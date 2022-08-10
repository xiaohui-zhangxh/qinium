class Qinium
  class Configurable < Hash
    def initialize(defaults = {})
      defaults.each_pair do |k, v|
        self[k.to_sym] = v.is_a?(Hash) ? Configurable.new(v) : v
      end
    end

    def []=(k, v)
      super(k.to_sym, v)
    end

    def method_missing(method, *args)
      if method.to_s.end_with?("=")
        self[method.to_s[0..-2].to_sym] = args[0]
      else
        fetch(method.to_sym)
      end
    end

    def respond_to_missing?(method)
      key = method.to_s.end_with?("=") ? method.to_s[0..-2].to_sym : method
      key?(key)
    end
  end
end
