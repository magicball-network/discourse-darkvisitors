# frozen_string_literal: true

require "uri"
require "net/http"

module DarkVisitors
  class ServerAnalytics
    @headers = %w[
      User-Agent
      Referer
      From
      X-Country-Code
      X-Forwarded-For
      X-Real-IP
      Client-IP
      CF-Connecting-IP
      X-Cluster-Client-IP
      Forwarded
      X-Original-Forwarded-For
      Fastly-Client-IP
      True-Client-IP
      X-Appengine-User-IP
    ]
    @header_map =
      @headers.map { |k| ["HTTP_" + k.sub("-", "_").upcase, k] }.to_h

    def self.log_request(env, data)
      return if SiteSetting.darkvisitors_server_analytics == "disabled"
      if data[:has_auth_cookie] &&
           SiteSetting.darkvisitors_server_analytics == "anonymous_only"
        return
      end
      relpath = relative_request_path(env)
      if data[:is_background] || data[:is_api] || data[:is_user_api] ||
           ignore_path(relpath)
        return
      end
      return unless should_track(data, relpath)

      request = {
        request_path: env["REQUEST_PATH"],
        request_method: env["REQUEST_METHOD"],
        request_headers: {
          "Remote-Addr" => data[:request_remote_ip]
        }
      }
      @header_map.each do |key, header|
        next if env[key].blank?
        request[:request_headers][header] = env[key]
      end

      Scheduler::Defer.later("Track Dark Visitors") do
        uri =
          URI(
            SiteSetting.darkvisitors_server_analytics_api ||
              "https://api.darkvisitors.com/visits"
          )
        headers = {
          "Content-Type" => "application/json",
          "Authorization" => "Bearer " + SiteSetting.darkvisitors_access_token,
          "User-Agent" => HTTP_USER_AGENT
        }
        Net::HTTP.post(uri, request.to_json, headers)
      end
    end

    def self.relative_request_path(env)
      path = env["REQUEST_PATH"]
      path = path.delete_prefix(Discourse.base_path) if Discourse.base_path
      path
    end

    def self.ignore_path(path)
      # Never report these paths
      path.start_with?("/admin/", "/mini-profiler-resources/")
    end

    def self.should_track(data, path)
      if SiteSetting.darkvisitors_server_analytics_include == ""
        return data[:track_view]
      end
      opts = SiteSetting.darkvisitors_server_analytics_include.split("|")
      return true if opts.include?("everything")
      return true if opts.include?("not_found") && data[:status] == 404
      if opts.include?("uploads") && data[:status] == 200 &&
           path.start_with?("/uploads/")
        return true
      end
      data[:track_view]
    end
  end
end
