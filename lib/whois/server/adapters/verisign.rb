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


module Whois
  class Server
    module Adapters
      
      class Verisign < Base
        
        def request(qstring)
          response = ask_the_socket("=#{qstring}", host, DEFAULT_WHOIS_PORT)
          push_buffer response, host

          if endpoint = extract_referral(response)
            response = ask_the_socket(qstring, endpoint, DEFAULT_WHOIS_PORT)
            push_buffer response, endpoint
          end
        end

        private

          def extract_referral(response)
            if response =~ /Domain Name:/ && response =~ /Whois Server: (\S+)/
              $1
            end
          end

      end

    end
  end
end