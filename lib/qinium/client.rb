class Qinium
  class Client
    include Qinium::Utils

    attr_reader :config

    def initialize(config)
      @config = config
    end

    # rubocop: disable Style/SingleLineMethods
    def user_agent; config.user_agent end
    def access_key; config.access_key end
    def secret_key; config.secret_key end
    # rubocop: enable Style/SingleLineMethods

    def get(url, opts = {})
      opts[:raise] = true unless opts.key?(:raise)
      req_headers = {
        connection: "close",
        accept: "*/*",
        user_agent: user_agent
      }
      req_headers.merge!(opts[:headers]) if opts[:headers].is_a?(Hash)

      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      logger.debug "Get #{uri}"
      logger.debug " options: #{opts.to_json}"

      req = Net::HTTP::Get.new(uri)
      req_headers.each_pair do |key, value|
        req.add_field key, value
      end
      res = http.request(req)
      code = res.code.to_i
      body = res.body
      headers = res.header.to_hash.transform_values do |v|
        v.join(", ")
      end

      if headers["content-type"] == "application/json"
        body = begin
          JSON.parse(body)
        rescue StandardError
          {}
        end
      end
      raise APIError.new(code, body, headers) if opts[:raise] && !success?(code)

      [code, body, headers]
    end

    def post(url, req_body = "", opts = {})
      opts[:raise] = true unless opts.key?(:raise)
      req_headers = {
        connection: "close",
        accept: "*/*",
        user_agent: user_agent
      }
      req_headers.merge!(opts[:headers]) if opts[:headers].is_a?(Hash)

      uri = URI(url)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      logger.debug "POST #{uri}"
      logger.debug "    body: #{req_body[0, 50]}" if req_body.is_a?(String)
      logger.debug " headers: #{opts.to_json}"

      req = Net::HTTP::Post.new(uri)
      req_headers.each_pair do |key, value|
        req.add_field key, value
      end
      req.body = req_body
      res = http.request(req)
      code = res.code.to_i
      body = res.body
      headers = res.header.to_hash.transform_values do |v|
        v.join(", ")
      end
      if headers["content-type"] == "application/json"
        body = begin
          JSON.parse(body)
        rescue StandardError
          nil
        end
      end
      raise APIError.new(code, body, headers) if opts[:raise] && !success?(code)

      [code, body, headers]
    end

    def management_get(url)
      access_token = Auth.generate_access_token(access_key, secret_key, url)
      get(url, headers: {
            "Content-Type" => "application/x-www-form-urlencoded",
            "Authorization" => "QBox " + access_token
          })
    end

    def management_post(url, body = nil)
      body = JSON.dump(body) if body && body.size > 0
      access_token = Auth.generate_access_token(access_key, secret_key, url, body)
      post(url, body, headers: {
             "Content-Type" => "application/x-www-form-urlencoded",
             "Authorization" => "QBox " + access_token
           })
    end

    def self.success?(http_code)
      http_code.between?(200, 299)
    end

    def success?(http_code)
      self.class.success?(http_code)
    end
  end
end
