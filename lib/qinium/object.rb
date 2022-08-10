class Qinium
  class Object
    include Qinium::Utils

    attr_reader :client

    def initialize(client)
      @client = client
    end

    # rubocop: disable Style/SingleLineMethods, Rails/Delegate
    def config; client.config end
    def bucket; config.bucket end
    # rubocop: enable Style/SingleLineMethods, Rails/Delegate

    def mkblk(blk, token:, host: nil)
      host ||= config.up_host
      client.post("#{host}/mkblk/#{blk.size}", blk, headers: {
                    "Content-Type" => "application/octet-stream",
                    "Content-Length" => blk.size,
                    "Authorization" => "UpToken #{token}"
                  })
    end

    def mkfile(token:, file_size:, blocks:, key: nil, fname: nil, mime_type: nil, user_vars: nil)
      url = config.up_host
      url += "/mkfile/#{file_size}"
      url += "/key/#{urlsafe_base64_encode(key)}" if key
      url += "/fname/#{urlsafe_base64_encode(fname)}" if fname
      url += "/mimeType/#{urlsafe_base64_encode(mime_type)}" if mime_type
      url += "/x:user-var/#{urlsafe_base64_encode(user_vars)}" if user_vars
      client.post(url, blocks.join(","), headers: {
                    "Context-Type" => "text/plain",
                    "Authorization" => "UpToken #{token}"
                  })
    end

    def delete(key, bucket: self.bucket)
      client.management_post(config.rs_host + "/delete/" + Utils.encode_entry_uri(
        bucket, key
      ))
    end

    def list(bucket: self.bucket, marker: "", limit: 1000, prefix: "", delimiter: "")
      query_string = to_query_string(bucket: bucket, marker: marker, limit: limit, prefix: prefix,
                                     delimiter: delimiter)
      client.management_get(config.rsf_host + "/list?" + query_string)
    end
  end
end
