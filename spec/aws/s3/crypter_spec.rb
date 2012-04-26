require 'spec_helper'

module AWS
  class S3

    describe Crypter do
      let(:crypter) { Crypter.new }
      let(:cipher) { crypter.cipher }

      context "#encrypt_data" do
        before :all do
          RSpec::Mocks.setup(cipher)
          cipher.stub!(:random_key).and_return("random_key")
          cipher.stub!(:random_iv).and_return("random_iv")
          cipher.stub!(:update).and_return("edat")
          cipher.stub!(:final).and_return("a")
          @result = crypter.encrypt_data("data")
        end

        it "should generate a random key" do
          cipher.should have_received(:random_key)
        end

        it "should generate a random iv" do
          cipher.should have_received(:random_iv)
        end

        it "should encrypt the data" do
          cipher.should have_received(:update).with("data")
          cipher.should have_received(:final)
        end

        it "should return the encrypted data, key and iv" do
          @result[0].should == "edata"
          @result[1].should == "random_key"
          @result[2].should == "random_iv"
        end
      end

      context "#decrypt_data" do
        before :all do
          RSpec::Mocks.setup(cipher)
          cipher.stub!(:key=)
          cipher.stub!(:iv=)
          cipher.stub!(:update).and_return("dat")
          cipher.stub!(:final).and_return("a")
          @result = crypter.decrypt_data("edata", "random_key", "random_iv")
        end

        it "should set the key" do
          cipher.should have_received(:key=).with("random_key")
        end

        it "should set the iv" do
          cipher.should have_received(:iv=).with("random_iv")
        end

        it "should decrypt the data" do
          cipher.should have_received(:update).with("edata")
          cipher.should have_received(:final)
        end

        it "should return the unencrypted data" do
          @result.should == "data"
        end
      end
    end

  end
end