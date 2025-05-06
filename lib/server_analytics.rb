# frozen_string_literal: true

require "uri"
require "net/http"

module DarkVisitors
  class ServerAnalytics
    @headers = %w[
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
    ]
    @header_map =
      @headers.map { |k| ["HTTP_" + k.sub("-", "_").upcase, k] }.to_h

    def self.log_request(env, data)
      return if SiteSetting.darkvisitors_server_analytics == "disabled"
      if SiteSetting.darkvisitors_access_token.empty?
        Rails.logger.warn "Dark Visitors analytics not available because access token is not configured"
        return
      end
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
      return if ignore_user_agent(env["HTTP_USER_AGENT"])

      request = {
        request_path: env["REQUEST_PATH"],
        request_method: env["REQUEST_METHOD"],
        request_headers: {
        }
      }
      if data[:request_remote_ip]
        if data[:request_remote_ip].include?(":")
          request[:request_headers]["Remote-Addr"] = "[" +
            data[:request_remote_ip] + "]"
        else
          request[:request_headers]["Remote-Addr"] = data[:request_remote_ip]
        end
      end

      @header_map.each do |key, header|
        next if env[key].blank?
        request[:request_headers][header] = env[key]
      end

      Scheduler::Defer.later("Track Dark Visitors") { report_visit(request) }
    end

    def self.report_visit(request)
      if SiteSetting.darkvisitors_simulate
        Rails.logger.info "Dark Visitors analytics payload: #{request.to_json}"
        return
      end
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

    def self.relative_request_path(env)
      path = env["REQUEST_PATH"]
      path = path.delete_prefix(Discourse.base_path) if Discourse.base_path
      path
    end

    def self.ignore_path(path)
      # Never report these paths
      path.start_with?("/admin/", "/sidekiq/", "/mini-profiler-resources/")
    end

    def self.should_track(data, path)
      if SiteSetting.darkvisitors_server_analytics_include == ""
        return data[:track_view] == true
      end
      opts = SiteSetting.darkvisitors_server_analytics_include.split("|")
      return true if opts.include?("everything")
      return true if opts.include?("not_found") && data[:status] == 404
      if opts.include?("uploads") && data[:status] == 200 &&
           path.start_with?("/uploads/")
        return true
      end
      data[:track_view] == true
    end

    def self.ignore_user_agent(user_agent)
      return true if user_agent.empty?
      return false if SiteSetting.darkvisitors_server_analytics_ignore == ""
      agents = SiteSetting.darkvisitors_server_analytics_ignore.split("|")
      agents.any? { |s| user_agent.include?(s) }
    end
  end
end
