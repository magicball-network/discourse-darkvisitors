# frozen_string_literal: true

module ::DiscourseDarkvisitors::Jobs
  class UpdateRobotsTxt < ::Jobs::Scheduled
    every 1.day

    def execute(_args)
      DiscourseDarkvisitors::RobotsTxt.update_robots_txt
    end
  end
end
