module RorVsWild
  module Plugin
    class NetHttp
      HTTP = "http".freeze
      HTTPS = "https".freeze

      def self.setup
        return if !defined?(Net::HTTP)
        return if Net::HTTP.method_defined?(:request_without_rorvswild)

        Net::HTTP.class_eval do
          alias_method :request_without_rorvswild, :request

          def request(req, body = nil, &block)
            return request_without_rorvswild(req, body, &block) if request_called_twice?
            scheme = use_ssl? ? HTTPS : HTTP
            url = "#{req.method} #{scheme}://#{address}#{req.path}"
            RorVsWild.agent.measure_section(url, kind: HTTP) do
              request_without_rorvswild(req, body, &block)
            end
          end

          def request_called_twice?
            # Net::HTTP#request calls itself when connection is not started.
            # This condition prevents from counting twice the request.
            (current_section = RorVsWild::Section.current) && current_section.kind == HTTP
          end
        end
      end
    end
  end
end
