class Qinium
  module Utils
    extend self

    def urlsafe_base64_encode(content)
      Base64.encode64(content).strip.gsub("+", "-").gsub("/", "_").gsub(/\r?\n/, "")
    end

    def urlsafe_base64_decode(encoded_content)
      Base64.decode64 encoded_content.gsub("_", "/").gsub("-", "+")
    end

    def encode_entry_uri(bucket, key)
      entry_uri = bucket + ":" + key
      urlsafe_base64_encode(entry_uri)
    end

    def blank?(obj)
      case obj
      when String then obj.strip.empty?
      when NilClass then true
      when Array, Hash then obj.size.zero?
      else
        false
      end
    end

    def to_query_string(hash)
      args = []
      hash.keys.sort_by(&:to_s).each do |key|
        value = hash[key]
        next if value.nil?

        args.push("#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s).gsub("+", "%20")}")
      end
      args.join("&")
    end

    def logger
      @logger ||= Logger.new(STDOUT, level: Qinium.logger_level)
    end
  end
end
