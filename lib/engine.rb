# frozen_string_literal: true

module ::DarkVisitors
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DarkVisitors
  end
end
