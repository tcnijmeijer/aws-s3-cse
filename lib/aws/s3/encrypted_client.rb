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
        options[:metadata][HEADER_KEY] = Base64.strict_encode64(key)
        options[:metadata][HEADER_IV]  = Base64.strict_encode64(iv)
        options[:data]                 = Base64.strict_encode64(edata)
        super
      end

      def get_object(options = {})
        response = super

        ekey = response.http_response.headers["#{HEADER_META}-#{HEADER_KEY}"]
        iv   = response.http_response.headers["#{HEADER_META}-#{HEADER_IV}"]

        if ekey && iv
          ekey  = Base64.strict_decode64(ekey)
          iv    = Base64.strict_decode64(iv)
          edata = Base64.strict_decode64(response.data)
          key   = @public_encryption_key.public_decrypt(ekey)
          data  = crypter.decrypt_data(edata, key, iv)
          Core::MetaUtils.extend_method(response, :data) { data }
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