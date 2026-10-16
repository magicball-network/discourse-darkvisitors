# frozen_string_literal: true

# name: discourse-darkvisitors
# about: Connects to Known Agents (formerly known as Dark Visitors) to keep the robots.txt up to date and monitor crawlers and scrapers visiting your community.
# meta_topic_id: 365158
# version: 1.5
# authors: elmuerte
# url: https://github.com/magicball-network/discourse-darkvisitors
# required_version: 2026.1

enabled_site_setting :darkvisitors_enabled

module ::DiscourseDarkvisitors
  PLUGIN_NAME = "discourse-darkvisitors"
  HTTP_USER_AGENT =
    "#{PLUGIN_NAME}/1.0 (+https://github.com/magicball-network/discourse-darkvisitors)"

  module Jobs
  end
end

require_relative "lib/discourse_darkvisitors/engine"

after_initialize do
  require_relative "app/jobs/discourse_darkvisitors/scheduled/update_robots_txt"

  on(:robots_info) do |robots_info|
    DiscourseDarkvisitors::RobotsTxt.on_robots_info(robots_info)
  end
  on(:site_setting_changed) do |name, _old_value, _new_value|
    if %i[
         darkvisitors_robots_txt_enabled
         darkvisitors_access_token
         darkvisitors_robots_txt_agents
         darkvisitors_robots_txt_path
         darkvisitors_robots_txt_api
       ].include?(name)
      Jobs.enqueue(DiscourseDarkvisitors::Jobs::UpdateRobotsTxt)
    end
  end

  logger =
    lambda do |env, data|
      DiscourseDarkvisitors::ServerAnalytics.log_request(env, data)
    end
  Middleware::RequestTracker.register_detailed_request_logger(logger)
end
