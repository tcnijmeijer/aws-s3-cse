module AWS
  class S3
    module Model
      def client
        if @config.s3_client_side_encryption
          @config.send(:s3_encrypted_client)
        else
          @config.send(:s3_client)
        end
      end
    end

    class Bucket
      include S3::Model
    end

    class BucketCollection
      include S3::Model
    end

    class MultipartUpload
      include S3::Model
    end

    class MultipartUploadCollection
      include S3::Model
    end

    class ObjectCollection
      include S3::Model
    end

    class ObjectMetadata
      include S3::Model
    end

    class ObjectUploadCollection
      include S3::Model
    end

    class ObjectVersion
      include S3::Model
    end

    class ObjectVersionCollection
      include S3::Model
    end

    class PresignedPost
      include S3::Model
    end

    class S3Object
      include S3::Model
    end

    class Tree::ChildCollection
      include S3::Model
    end

    module Tree::Parent
      include S3::Model
    end

    class UploadedPart
      include S3::Model
    end

    class UploadedPartCollection
      include S3::Model
    end
  end
end