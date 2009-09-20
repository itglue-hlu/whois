#
# = Ruby Whois
#
# An intelligent pure Ruby WHOIS client.
#
#
# Category::    Net
# Package::     Whois
# Author::      Simone Carletti <weppos@weppos.net>
# License::     MIT License
#
#--
#
#++


require 'whois/response/parsers/base'


module Whois

  class Response

    attr_reader :server
    attr_reader :parts

    def initialize(server, parts)
      @parts  = parts
      @server = server
    end

    
    def to_s
      content.to_s
    end
    
    def inspect
      content.inspect
    end
    
    # Invokes <tt>match</tt> on response <tt>@content</tt>
    # and returns the <tt>MatchData</tt> or <tt>nil</tt>.
    def match(pattern)
      content.match(pattern)
    end
    
    # Returns true if the <tt>object</tt> is the same object,
    # or is a string and has the same content.
    def ==(other)
      (other.equal?(self)) ||
      # This option should be deprecated
      (other.instance_of?(String) && other == self.to_s) ||
      (other.instance_of?(Response) && other.to_s == self.to_s)
    end
    
    # Delegates to ==.
    def eql?(other)
      self == other
    end


    def content
      @content ||= parts.map { |response, host| response }.join("\n")
    end

    # Returns whether this response changed compared to <tt>other</tt>.
    #
    # Comparing the Response contents is not always as trivial as it seems.
    # Whois servers sometimes inject dynamic method into the whois response such as
    # the timestamp the request was generated.
    # This causes two responses to be different even if they actually should be considered equal
    # because the registry data didn't change.
    #
    # This method should provide a bulletproof way to detect whether this response
    # changed if compared with <tt>other</tt>.
    def changed?(other)
      !unchanged?(other)
    end

    # The opposite of <tt>changed?</tt>.
    def unchanged?(other)
      self == other ||
      parser.unchanged?(other.parser)
    end


    # Invokes <tt>match</tt> and returns <tt>true</tt> if <tt>pattern</tt>
    # matches <tt>@content</tt>, <tt>false</tt> otherwise.
    def match?(pattern)
      !content.match(pattern).nil?
    end
    
    # Invokes <tt>match</tt> and returns the first useful match,
    # nil otherwise.
    #
    #   "My car is blue".i_m_feeling_lucky(/^My car is (\w+)$/)
    #   # => "blue"
    #   "My car is blue".i_m_feeling_lucky(/^My bike is (\w+)$/)
    #   # => nil
    #
    def i_m_feeling_lucky(pattern, &block)
      if matches = match(pattern)
        m = matches[1]
        m = yield(m) if block_given?
        m
      end
    end
    alias :imfl :i_m_feeling_lucky
    
    
    # Lazy-loads and returns current response parser.
    def parser
      @parser ||= self.class.parser_klass(parts.first.last).new(self)
    end


    protected
      
      # Delegates all method calls to the internal parser.
      def method_missing(method, *args, &block)
        if Parsers::Base.allowed_methods.include?(method)
          parser.send(method, *args, &block)
        else
          super
        end
      end
      
      
      def self.parser_klass(host)
        file = "whois/response/parsers/#{host}.rb"
        require file
        
        name = host_to_parser(host)
        Parsers.const_get(name)
      
      rescue LoadError
        raise ParserNotFound, 
          "Unable to find a parser for the server `#{host}'"
      end
      
      def self.host_to_parser(host)
        host.to_s.
          gsub(/\./, '_').
          gsub(/(?:^|_)(.)/)  { $1.upcase }
      end
    
  end

end