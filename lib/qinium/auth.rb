class Qinium
  module Auth
    extend self

    def calculate_hmac_sha1_digest(secret_key, str)
      OpenSSL::HMAC.digest(OpenSSL::Digest.new("sha1"), secret_key, str)
    end

    def generate_access_token(access_key, secret_key, url, body = {})
      encoded_sign = generate_access_token_sign_with_mac(secret_key, url, body)

      "#{access_key}:#{encoded_sign}"
    end

    def generate_access_token_sign_with_mac(secret_key, url, body)
      ### 解析URL，生成待签名字符串
      uri = URI.parse(url)
      signing_str = uri.path

      # 如有QueryString部分，则需要加上
      query_string = uri.query
      signing_str += "?" + query_string if query_string.is_a?(String) && !query_string.empty?

      # 追加换行符
      signing_str += "\n"

      # 如果有Body，则也加上
      # （仅限于mime == "application/x-www-form-urlencoded"的情况）
      signing_str += body if body.is_a?(String) && !body.strip.empty?

      ### 生成数字签名
      sign = calculate_hmac_sha1_digest(secret_key, signing_str)
      Utils.urlsafe_base64_encode(sign)
    end

    def authorize_download_url(domain, key, access_key, secret_key, args = {})
      url_encoded_key = key.split("/").map { |s| CGI.escape(s) }.join("/")
      schema = args[:schema] || "http"
      port   = args[:port]

      download_url = if port.nil?
                       "#{schema}://#{domain}/#{url_encoded_key}"
                     else
                       "#{schema}://#{domain}:#{port}/#{url_encoded_key}"
                     end

      ### URL变换：追加FOP指令
      if args[:fop].is_a?(String) && args[:fop] != ""
        download_url = if download_url.include?("?")
                         # 已有参数
                         "#{download_url}&#{args[:fop]}"
                       else
                         # 尚无参数
                         "#{download_url}?#{args[:fop]}"
                       end
      end

      ### 授权期计算
      e = Time.now.to_i + args[:expires_in]

      ### URL变换：追加授权期参数
      download_url = if download_url.include?("?")
                       # 已有参数
                       "#{download_url}&e=#{e}"
                     else
                       # 尚无参数
                       "#{download_url}?e=#{e}"
                     end

      ### 生成数字签名
      sign = calculate_hmac_sha1_digest(secret_key, download_url)
      encoded_sign = Utils.urlsafe_base64_encode(sign)

      ### 生成下载授权凭证
      dntoken = "#{access_key}:#{encoded_sign}"

      ### 返回下载授权URL
      "#{download_url}&token=#{dntoken}"
    end
  end
end
