# frozen_string_literal: true

module ::DiscourseDarkvisitors
  class Engine < ::Rails::Engine
    engine_name PLUGIN_NAME
    isolate_namespace DiscourseDarkvisitors
  end
end
