# name: discourse-darkvisitors
# about: connects to [Dark Visitors](https://darkvisitors.com/) to keep the robots.txt up to date and monitor crawlers and scrapers visiting your forum.
# meta_topic_id:
# version: 0.1
# authors: elmuerte
# url: https://github.com/magicball-network/discourse-darkvisitors
# required_version: 3.4.0

enabled_site_setting :darkvisitors_enabled

module ::DarkVisitors
  PLUGIN_NAME = "discourse-darkvisitors"
end

after_initialize do
  #
end
