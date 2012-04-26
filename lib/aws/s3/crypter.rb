require 'openssl'

module AWS
  class S3
    class Crypter
      attr_reader :cipher

      def initialize(cipher_name = 'aes-256-cbc')
        @cipher = OpenSSL::Cipher::Cipher.new(cipher_name)
      end

      def encrypt_data(data)
        cipher.encrypt

        key   = cipher.random_key
        iv    = cipher.random_iv
        edata = cipher.update(data)
        edata << cipher.final

        [edata, key, iv]
      end

      def decrypt_data(edata, key, iv)
        cipher.decrypt

        cipher.key = key
        cipher.iv  = iv

        data = cipher.update(edata)
        data << cipher.final
        data.to_s
      end
    end
  end
end