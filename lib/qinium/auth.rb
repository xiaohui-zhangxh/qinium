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
  end
end
