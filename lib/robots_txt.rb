# frozen_string_literal: true

require "uri"
require "net/http"

module DarkVisitors
  ROBOTS_TXT = "robots-txt"

  class RobotsTxt
    def self.on_robots_info(robots_info)
      return unless SiteSetting.darkvisitors_robots_txt_enabled

      config = PluginStore.get(PLUGIN_NAME, ROBOTS_TXT) || return

      config[:agents].each do |entry|
        unless robots_info[:agents].any? { |agent|
                 agent[:name] == entry[:name]
               }
          robots_info[:agents] << entry
        end
      end
      robots_info[:header] = robots_info[:header] +
        "\n# Augmented by Dark Visitors on #{config[:last_update]} with #{config[:agents].count} agents"
    end

    def self.update_robots_txt
      return unless SiteSetting.darkvisitors_robots_txt_enabled
      if SiteSetting.darkvisitors_access_token == ""
        Rails.logger.warn "Cannot update robots.txt from Dark Visitors. No access_token configured."
        return
      end
      Rails.logger.info "Updating Dark Visitors robots.txt"

      uri =
        URI(
          SiteSetting.darkvisitors_robots_txt_api ||
            "https://api.darkvisitors.com/robots-txts"
        )
      request = {
        "agent_types" =>
          SiteSetting.darkvisitors_robots_txt_agents.split("|") || [],
        "disallow" => SiteSetting.darkvisitors_robots_txt_path || "/"
      }.to_json
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer " + SiteSetting.darkvisitors_access_token,
        "User-Agent" => HTTP_USER_AGENT
      }
      response = Net::HTTP.post(uri, request, headers)
      unless response.code == "200"
        Rails.logger.error "Dark Visitors robots-txt API failure: #{response.code}"
        return
      end

      agents = []
      agent = { name: nil, disallow: [] }
      response
        .body
        .each_line(chomp: true) do |ln|
          next if ln.start_with?("#")
          pair = ln.split(/:/, 2)
          next if pair.empty?
          key = pair[0].downcase
          value = pair[1].strip
          if key == "user-agent"
            agents << agent if agent[:name] && !agent[:disallow].empty?
            agent = { name: value, disallow: [] }
          elsif key == "disallow"
            agent[:disallow] << value
          end
        end
      agents << agent if agent[:name] && !agent[:disallow].empty?

      PluginStore.set(
        PLUGIN_NAME,
        ROBOTS_TXT,
        { last_update: DateTime.now.to_s, agents: agents }
      )
      Rails.logger.info "Received #{agents.count} agents to deny from Dark Visitors"
    end
  end
end
