class Qinium
  class PutPolicy
    include Qinium::Utils

    DEFAULT_AUTH_SECONDS = 300

    PARAMS = {
      # 字符串类型参数
      scope: "scope",
      is_prefixal_scope: "isPrefixalScope",
      save_key: "saveKey",
      end_user: "endUser",
      return_url: "returnUrl",
      return_body: "returnBody",
      callback_url: "callbackUrl",
      callback_host: "callbackHost",
      callback_body: "callbackBody",
      callback_body_type: "callbackBodyType",
      persistent_ops: "persistentOps",
      persistent_notify_url: "persistentNotifyUrl",
      persistent_pipeline: "persistentPipeline",

      # 数值类型参数
      deadline: "deadline",
      insert_only: "insertOnly",
      fsize_min: "fsizeMin",
      fsize_limit: "fsizeLimit",
      detect_mime: "detectMime",
      mime_limit: "mimeLimit",
      uphosts: "uphosts",
      global: "global",
      delete_after_days: "deleteAfterDays",
      file_type: "fileType"
    }

    PARAMS.each_pair do |key, _|
      attr_accessor key
    end

    attr_reader :config, :bucket, :key

    def initialize(config, bucket: nil, key: nil, expires_in: DEFAULT_AUTH_SECONDS)
      @config = config
      scope!(bucket || config.bucket, key)
      expires_in! expires_in
    end

    def scope!(bucket, key = nil)
      @bucket = bucket
      @key    = key

      @scope = if key.nil?
                 # 新增语义，文件已存在则失败
                 bucket
               else
                 # 覆盖语义，文件已存在则直接覆盖
                 "#{bucket}:#{key}"
               end
    end

    def expires_in!(seconds)
      @deadline = Time.now.to_i + seconds
    end

    def to_json(*_args)
      args = {}

      PARAMS.each_pair do |key, fld|
        val = __send__(key)
        args[fld] = val unless val.nil?
      end

      args.to_json
    end

    def to_token
      access_key = config.access_key
      secret_key = config.secret_key

      ### 生成待签名字符串
      encoded_put_policy = urlsafe_base64_encode(to_json)

      ### 生成数字签名
      sign = Auth.calculate_hmac_sha1_digest(secret_key, encoded_put_policy)
      encoded_sign = urlsafe_base64_encode(sign)

      ### 生成上传授权凭证
      "#{access_key}:#{encoded_sign}:#{encoded_put_policy}"
    end
  end
end
