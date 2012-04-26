require 'spec_helper'

module AWS
  class S3
    shared_examples_for "an S3 model" do |*args|
      let(:rsa_key) { OpenSSL::PKey::RSA.generate(1024) }

      let(:config) do
        AWS.config(:access_key_id => "access key id", :secret_access_key => "secret access key",
                   :s3_private_key => rsa_key, :s3_public_key => rsa_key)
      end

      let(:instance) do
        options = args.last.is_a?(Hash) ? args.pop : {} 
        options[:config] = config
        args << options
        described_class.new(*args)
      end

      it "should include the S3::Model module" do
        described_class.should include(S3::Model)
      end

      it "returns a normal S3::Client in client side encryption is off" do
        AWS.config(:s3_client_side_encryption => false)
        instance.client.class.should == S3::Client
      end

      it "returns a S3::EncryptedClient in client side encryption is on" do
        AWS.config(:s3_client_side_encryption => true)
        instance.client.class.should == S3::EncryptedClient
      end
    end

    describe Bucket do
      it_should_behave_like "an S3 model", 'foo'
    end

    describe BucketCollection do
      it_should_behave_like "an S3 model"
    end

    describe MultipartUpload do
      it_should_behave_like "an S3 model", Object.new, "123"
    end

    describe MultipartUploadCollection do
      it_should_behave_like "an S3 model", Object.new
    end

    describe ObjectCollection do
      it_should_behave_like "an S3 model", Object.new
    end

    describe ObjectMetadata do
      it_should_behave_like "an S3 model", Object.new
    end

    describe ObjectUploadCollection do
      it_should_behave_like "an S3 model", S3Object.new(Bucket.new('bu'), 'foo')
    end

    describe ObjectVersion do
      it_should_behave_like "an S3 model", Object.new, 'version_id'
    end

    describe ObjectVersionCollection do
      it_should_behave_like "an S3 model", Object.new
    end

    describe PresignedPost do
      it_should_behave_like "an S3 model", Object.new
    end

    describe S3Object do
      it_should_behave_like "an S3 model", Object.new, 'foo'
    end

    describe Tree::ChildCollection do
      it_should_behave_like "an S3 model", Object.new, []
    end

    describe UploadedPart do
      it_should_behave_like "an S3 model", Object.new, 1
    end

    describe UploadedPartCollection do
      it_should_behave_like "an S3 model", Object.new
    end
  end
end