module AWS
  class S3
    module Errors

      class UnencryptedData < AWS::Errors::Base
        include AWS::Errors::ClientError

        def code; "UnencryptedData"; end

        def initialize(req, resp)
          super(req, resp, "UnencryptedData")
        end
      end

      class DecryptionError < StandardError
        attr_reader :public_key
        attr_reader :env_key
        attr_reader :original

        def initialize(public_key, env_key, original)
          @public_key = public_key
          @env_key    = env_key
          @original   = original
          super("Could not decrypt envelope key using the given public key")
        end
      end

    end
  end
end