# frozen_string_literal: true

module DiscourseDarkvisitors
  class RequestUtils
    HEADERS = %w[
      User-Agent
      Referer
      From
      X-Forwarded-For
      X-Real-IP
      Forwarded
      X-Original-Forwarded-For
      Accept
      Accept-Language
      Accept-Encoding
      Connection
      Origin
      Signature
      Signature-Agent
      Signature-Input
    ]
    HEADER_MAP = HEADERS.index_by { |k| "HTTP_" + k.sub("-", "_").upcase }

    def self.safe_headers(env, data = {})
      request_headers = {}

      if data[:request_remote_ip]
        if data[:request_remote_ip].include?(":")
          request_headers["Remote-Addr"] = "[" + data[:request_remote_ip] + "]"
        else
          request_headers["Remote-Addr"] = data[:request_remote_ip]
        end
      end

      HEADER_MAP.each do |key, header|
        next if env[key].blank?
        request_headers[header] = env[key]
      end

      request_headers
    end
  end
end
