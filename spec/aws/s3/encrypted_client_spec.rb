require 'spec_helper'

module AWS
  class S3

    describe EncryptedClient do
      describe "getting one" do
        let(:credentials) do
          { :access_key_id => "access key id",
            :secret_access_key => "secret access key" }
        end

        let(:rsa_key) { OpenSSL::PKey::RSA.generate(1024) }

        it "accepts the assymetric key via a hash" do
          client = EncryptedClient.new(credentials.merge(:s3_private_key => rsa_key, :s3_public_key => rsa_key))

          client.public_encryption_key.should  == rsa_key
          client.private_encryption_key.should == rsa_key
        end

        it "accepts the assymetric key as part of a config" do
          config = AWS.config.with(credentials).with(:s3_private_key => rsa_key, :s3_public_key => rsa_key)
          client = EncryptedClient.new(:config => config)

          client.public_encryption_key.should  == rsa_key
          client.private_encryption_key.should == rsa_key
        end

        it "accepts the assymetric key as part of the default AWS.config" do
          AWS.config(:s3_private_key => rsa_key, :s3_public_key => rsa_key)
          client = EncryptedClient.new(credentials)

          client.public_encryption_key.should  == rsa_key
          client.private_encryption_key.should == rsa_key

          AWS.config(:s3_private_key => nil, :s3_public_key => nil)
        end

        it "requires an assymetric key" do
          lambda do
            EncryptedClient.new(credentials)
          end.should raise_error(/missing public and\/or private key/)
        end

        it 'should be accessible from the configuration' do
          config = AWS.config.with(:access_key_id => 'foo', :secret_access_key => 'bar',
                                   :s3_private_key => rsa_key, :s3_public_key => rsa_key)
          config.s3_encrypted_client.should be_a(S3::EncryptedClient)
        end
      end

      context '#put_object' do
        let :rsa_key do
          key = OpenSSL::PKey::RSA.generate(1024)
          key.stub(:private_encrypt).and_return("EKEY")
          key
        end

        let :credentials do
          { :access_key_id => "access key id", :secret_access_key => "secret access key" }
        end

        let :opts do
          {:bucket_name => 'foo', :key => 'some/key', :data => 'HELLO'}
        end

        let :crypter do
          crypter = Crypter.new
          crypter.stub(:encrypt_data).and_return(["HARRO", "KEY", "VECTOR"])
          crypter
        end

        let :client do
          client = EncryptedClient.new(credentials.merge(:s3_private_key => rsa_key, :s3_public_key => rsa_key))
          client.crypter = crypter
          client
        end

        before :all do

          class Client
            def super_calls
              @super_calls ||= []
            end

            def put_object opts
              self.super_calls << [:put_object, opts]
            end
          end

          client.put_object(:data => "HELLO", :key => "file", :bucket_name => "bucket")
        end

        it "should encrypt the data using a Crypter" do
          crypter.should have_received(:encrypt_data).with("HELLO")
        end

        it "should encrypt the envelope key using the private encryption key" do
          rsa_key.should have_received(:private_encrypt).with("KEY")
        end

        it "should call super" do
          client.super_calls.size.should == 1
          client.super_calls.first.first.should == :put_object
        end

        it "should call super with encrypted data" do
          args = client.super_calls.first.last
          args[:data].should == "HARRO"
        end

        it "should call super with the encrypted envelope key as metadata" do
          args = client.super_calls.first.last
          args[:metadata]["x-amz-key"].should == URI.encode(Base64.encode64("EKEY"))
        end

        it "should call super with the initialization vector as metadata" do
          args = client.super_calls.first.last
          args[:metadata]["x-amz-iv"].should == URI.encode(Base64.encode64("VECTOR"))
        end
      end

      context '#get_object' do
        let :rsa_key do
          key = OpenSSL::PKey::RSA.generate(1024)
          key.stub(:public_decrypt).and_return("KEY")
          key
        end

        let :credentials do
          { :access_key_id => "access key id", :secret_access_key => "secret access key" }
        end

        let :crypter do
          crypter = Crypter.new
          crypter.stub(:decrypt_data).and_return("HELLO")
          crypter
        end

        let :client do
          client = EncryptedClient.new(credentials.merge(:s3_private_key => rsa_key, :s3_public_key => rsa_key))
          client.crypter = crypter
          client
        end

        before :all do

          class Client
            def super_calls
              @super_calls ||= []
            end

            def get_object opts
              self.super_calls << [:get_object, opts]

              if opts[:key] == "file"
                resp = AWS::Core::Http::Response.new
                resp.body = "HARRO"
                resp.headers['x-amz-meta-x-amz-key'] = URI.encode(Base64.encode64('EKEY'))
                resp.headers['x-amz-meta-x-amz-iv']  = URI.encode(Base64.encode64('VECTOR'))
                resp = AWS::Core::Response.new(nil, resp)
                Core::MetaUtils.extend_method(resp, :data) { resp.http_response.body }
              else
                resp = AWS::Core::Http::Response.new
                resp.body = "HELLO"
                resp = AWS::Core::Response.new(nil, resp)
                Core::MetaUtils.extend_method(resp, :data) { resp.http_response.body }
              end

              resp
            end
          end

          @response = client.get_object(:key => "file", :bucket_name => "bucket")
        end

        it "should call super" do
          client.super_calls.size.should == 1
          client.super_calls.first.first.should == :get_object
        end

        it "should decrypt the envelope key using the private encryption key" do
          rsa_key.should have_received(:public_decrypt).with("EKEY")
        end

        it "should decrypt the data using a Crypter" do
          crypter.should have_received(:decrypt_data).with("HARRO", "KEY", "VECTOR")
        end

        it "should return the unencrypted data" do
          @response.data.should == "HELLO"
        end

        it "should raise an error if the resource is unencrypted" do
          lambda { client.get_object(:key => "other_file", :bucket_name => "bucket") }.
            should raise_error(Errors::UnencryptedData)
        end

        it "should handle an error when decryption the envelope key" do
          rsa_key.stub(:public_decrypt).and_raise(OpenSSL::PKey::RSAError.new)
          lambda { client.get_object(:key => "file", :bucket_name => "bucket") }.
            should raise_error(Errors::DecryptionError)
        end
      end
    end
    
  end
end
