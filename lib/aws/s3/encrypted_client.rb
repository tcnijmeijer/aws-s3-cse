require 'stringio'

module AWS
  class S3
    class EncryptedClient < Client
      attr_reader :private_encryption_key
      attr_reader :public_encryption_key

      HEADER_META = "x-amz-meta"
      HEADER_KEY  = "x-amz-key"
      HEADER_IV   = "x-amz-iv"

      def initialize(options = {})
        config = (options[:config] || AWS.config).with(options)
        @private_encryption_key = config.s3_private_key
        @public_encryption_key  = config.s3_public_key
        raise "missing public and/or private key" unless private_encryption_key && public_encryption_key
        super
      end

      def put_object(options = {})
        if block_given?
          buffer = StringIO.new
          yield buffer
          options[:data] = buffer.string
        end

        edata, key, iv = crypter.encrypt_data(options[:data])
        key = @private_encryption_key.private_encrypt(key)

        options[:metadata]           ||= {}
        options[:metadata][HEADER_KEY] = URI.encode(Base64.encode64(key))
        options[:metadata][HEADER_IV]  = URI.encode(Base64.encode64(iv))
        options[:data]                 = edata
        super
      end

      def get_object(options = {})
        response = super

        ekey = response.http_response.headers["#{HEADER_META}-#{HEADER_KEY}"]
        iv   = response.http_response.headers["#{HEADER_META}-#{HEADER_IV}"]

        if ekey && iv
          ekey  = Base64.decode64(URI.decode(ekey))
          iv    = Base64.decode64(URI.decode(iv))
          edata = response.data

          begin
            key = @public_encryption_key.public_decrypt(ekey)
          rescue Exception => e
            raise Errors::DecryptionError.new(@public_encryption_key, ekey, e)
          end

          data  = crypter.decrypt_data(edata, key, iv)
          Core::MetaUtils.extend_method(response, :data) { data }
        else
          raise Errors::UnencryptedData.new(response.http_request, response.http_response)
        end

        response
      end

      def crypter=(crypter)
        @crypter = crypter
      end

      def crypter
        @crypter ||= Crypter.new
      end
    end
  end
end