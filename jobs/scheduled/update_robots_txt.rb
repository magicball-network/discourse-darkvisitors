# frozen_string_literal: true

module Jobs
  class ::DarkVisitors::Jobs::UpdateRobotsTxt < ::Jobs::Scheduled
    every 1.day

    def execute(args)
      DarkVisitors::RobotsTxt.update_robots_txt
    end
  end
end
