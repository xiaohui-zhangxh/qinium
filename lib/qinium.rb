class Qinium
  require "logger"
  require "base64"
  require "tempfile"
  require "openssl"
  require "digest/sha1"
  require "cgi"
  require "net/http"
  require "json"
  require "qinium/version"
  require "qinium/errors"
  require "qinium/utils"
  require "qinium/configurable"
  require "qinium/config"
  require "qinium/client"
  require "qinium/host_manager"
  require "qinium/auth"
  require "qinium/object"
  require "qinium/put_policy"

  @logger_level = :info
  class << self
    attr_accessor :logger_level
  end

  attr_reader :config

  def initialize(options = {})
    @config = Config.new(options)
  end

  def object
    @object ||= Object.new(client)
  end

  def client
    @client ||= Client.new(config)
  end
end
