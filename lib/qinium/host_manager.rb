class Qinium
  class HostManager
    class Cache
      def initialize
        @mutex = Mutex.new
        @hosts = {}
      end

      def read(access_key, bucket, &block)
        @mutex.synchronize do
          key = cache_key(access_key, bucket)
          data = @hosts[key]
          if data && Time.now.to_i > data["expires_at"]
            @hosts.delete key
            data = nil
          end
          if data.nil?
            data = block.call
            data["expires_at"] = Time.now.to_i + data["ttl"]
            @hosts[key] = data.freeze
          end
          data
        end
      end

      def write(access_key, bucket, hosts)
        @mutex.synchronize do
          @hosts[cache_key(access_key, bucket)] = hosts
        end
      end

      def delete(access_key, bucket)
        @mutex.synchronize do
          @hosts.delete(cache_key(access_key, bucket))
        end
      end

      def cache_key(access_key, bucket)
        Digest::SHA1.base64digest "#{access_key}-#{bucket}"
      end
    end

    def self.cache
      @cache ||= Cache.new
    end

    attr_reader :config

    def initialize(config)
      @config = config
    end

    def up_host(bucket, opts = {})
      up_hosts(bucket, opts)[0]
    end

    def up_hosts(bucket, opts = {})
      hosts = hosts(bucket)
      hosts[extract_protocol(opts)]["up"]
    end

    def hosts(bucket)
      raise Error, "access_key is missing" if Utils.blank?(access_key)
      raise Error, "bucket is missing" if Utils.blank?(bucket)

      cache.read(access_key, bucket) do
        query = Utils.to_query_string(ak: access_key, bucket: bucket)
        url = "#{config.uc_host}/v1/query?#{query}"
        http = Client.new(config)
        code, body, headers = http.get(url)
        raise APIError.new(code, body, headers) unless Client.success?(code)

        body
      end
    end

    private

    def cache
      self.class.cache
    end

    def access_key
      config.access_key
    end

    def extract_protocol(opts)
      (opts[:protocol] || config.protocol).to_s
    end
  end
end
