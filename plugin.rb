# frozen_string_literal: true

# name: discourse-darkvisitors
# about: Connects to Dark Visitors to keep the robots.txt up to date and monitor crawlers and scrapers visiting your forum.
# meta_topic_id:
# version: 1.0
# authors: elmuerte
# url: https://github.com/magicball-network/discourse-darkvisitors
# required_version: 3.4.0

enabled_site_setting :darkvisitors_enabled

module ::DarkVisitors
  PLUGIN_NAME = "discourse-darkvisitors"
  HTTP_USER_AGENT =
    "#{PLUGIN_NAME}/1.0 (+https://github.com/magicball-network/discourse-darkvisitors)"
end
module ::DarkVisitors::Jobs
end

after_initialize do
  require_relative "lib/engine.rb"

  require_relative "lib/robots_txt.rb"
  require_relative "jobs/scheduled/update_robots_txt"

  require_relative "lib/server_analytics.rb"

  on(:robots_info) do |robots_info|
    DarkVisitors::RobotsTxt.on_robots_info(robots_info)
  end
  on(:site_setting_changed) do |name, old_value, new_value|
    if %i[
         darkvisitors_robots_txt_enabled
         darkvisitors_access_token
         darkvisitors_robots_txt_agents
         darkvisitors_robots_txt_path
         darkvisitors_robots_txt_api
       ].include?(name)
      Jobs.enqueue(DarkVisitors::Jobs::UpdateRobotsTxt)
    end
  end

  logger =
    lambda { |env, data| DarkVisitors::ServerAnalytics.log_request(env, data) }
  Middleware::RequestTracker.register_detailed_request_logger(logger)
end
