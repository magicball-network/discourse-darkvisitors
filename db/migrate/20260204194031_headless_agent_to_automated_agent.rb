# frozen_string_literal: true

class HeadlessAgentToAutomatedAgent < ActiveRecord::Migration[7.2]
  def up
    execute "UPDATE site_settings SET value = REPLACE(value, 'Headless Agent', 'Automated Agent') WHERE name = 'darkvisitors_robots_txt_agents' AND value LIKE '%Headless Agent%'"
  end

  def down
    execute "UPDATE site_settings SET value = REPLACE(value, 'Automated Agent', 'Headless Agent') WHERE name = 'darkvisitors_robots_txt_agents' AND value LIKE '%Automated Agent%'"
  end
end
