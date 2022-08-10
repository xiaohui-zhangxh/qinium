class Qinium
  Error = Class.new(StandardError)

  class APIError < StandardError
    attr_reader :code, :body, :headers

    def initialize(code, body, headers)
      @code = code
      @body = body
      @headers = headers
      super(body)
    end
  end
end
