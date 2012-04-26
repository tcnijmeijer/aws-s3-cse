AWS::Core::Configuration.module_eval do

  add_option :s3_client_side_encryption, nil
  add_option :s3_private_key, nil
  add_option :s3_public_key, nil

  needs = [
    :signer, 
    :http_handler, 
    :s3_endpoint,
    :s3_port,
    :s3_private_key,
    :s3_public_key,
    :max_retries,
    :stub_requests?,
    :proxy_uri,
    :use_ssl?,
    :ssl_verify_peer?,
    :ssl_ca_file,
    :user_agent_prefix,
    :logger,
    :log_formatter,
    :log_level,
  ]

  create_block = lambda do |config| 
    AWS::S3::EncryptedClient.new(:config => config)
  end

  add_option_with_needs :s3_encrypted_client, needs, &create_block
end