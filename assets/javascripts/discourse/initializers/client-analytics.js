import loadScript from "discourse/lib/load-script";
import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "discourse-darkvisitors",

  initialize(container) {
    const siteSetting = container.lookup("service:site-settings");
    if (
      siteSetting.darkvisitors_client_analytics === "disabled" ||
      siteSetting.darkvisitors_client_analytics_project_key === ""
    ) {
      return;
    }
    withPluginApi("1.34.0", (api) => {
      if (
        siteSetting.darkvisitors_client_analytics === "anonymous_only" &&
        api.getCurrentUser()
      ) {
        return;
      }
      const src =
        siteSetting.darkvisitors_client_analytics_script +
        "?project_key=" +
        siteSetting.darkvisitors_client_analytics_project_key;
      loadScript(src, { scriptTag: true });
    });
  },
};
