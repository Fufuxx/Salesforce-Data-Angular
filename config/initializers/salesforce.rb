module OmniAuth
  module Strategies
    class Salesforce
      def raw_info
        access_token.options[:mode] = :query
        access_token.options[:param_name] = :oauth_token
        u = URI.parse(access_token['id'])
        u.host = URI.parse(access_token['instance_url']).host
        @raw_info ||= access_token.post(u.to_s).parsed
      end
    end

  end
end
