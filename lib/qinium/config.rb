class Qinium
  class Config < Configurable
    def initialize(options = {})
      options[:protocol] ||= :https
      options = if options[:protocol] == :http
                  http_options.merge(options)
                else
                  https_options.merge(options)
                end
      super(default_options.merge(options))
    end

    def up_host(bucket = self.bucket)
      raw = self[:up_host]
      unless raw.to_s.strip.empty?
        normalize_qiniu_up_base_url(raw.to_s)
      else
        HostManager.new(self).up_host(bucket)
      end
    end

    def fetch_host(bucket = self.bucket, opts = {})
      self[:fetch_host] || HostManager.new(self).fetch_host(bucket, opts)
    end

    def put_policy_options
      @put_policy_options ||= self[:put_policy_options] || Configurable.new
    end

    private

    # Bare hostname is typical; optional full http(s) URL. Scheme defaults from #protocol.
    def normalize_qiniu_up_base_url(url)
      s = url.strip.sub(%r{/+\z}, "")
      return s if s.match?(%r{\Ahttps?://}i)

      # 仅域名时：http(s) 由 protocol 决定（支持 Symbol 或 ENV 里的 "http"/"https" 字符串）
      proto = protocol.to_s.downcase == "http" ? "http" : "https"
      "#{proto}://#{s.sub(%r{\A//+}, "")}"
    end

    def default_options
      {
        user_agent: "QiniumRuby/#{VERSION} (#{RUBY_PLATFORM}) Ruby/#{RUBY_VERSION}",
        method: :post,
        content_type: "application/x-www-form-urlencoded",
        auth_url: "https://acc.qbox.me/oauth2/token",
        access_key: "",
        secret_key: "",
        auto_reconnect: true,
        max_retry_times: 3,
        block_size: 1024 * 1024 * 4,
        chunk_size: 1024 * 256,
        enable_debug: true,
        tmpdir: Dir.tmpdir + File::SEPARATOR + "QiniuRuby",
        multi_region: false,
        public: true
      }.freeze
    end

    def http_options
      {
        rs_host: "http://rs.qiniu.com",
        rsf_host: "http://rsf.qbox.me",
        pub_host: "http://pu.qbox.me:10200",
        eu_host: "http://eu.qbox.me",
        uc_host: "http://uc.qbox.me",
        api_host: "http://api.qiniu.com",
        protocol: :http
      }.freeze
    end

    def https_options
      {
        rs_host: "https://rs.qbox.me",
        rsf_host: "https://rsf.qbox.me",
        pub_host: "https://pu.qbox.me",
        eu_host: "https://eu.qbox.me",
        uc_host: "https://uc.qbox.me",
        api_host: "https://api.qiniu.com",
        protocol: :https
      }.freeze
    end
  end
end
