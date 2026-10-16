import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "darkvisitors-admin-plugin-configuration-nav",

  initialize(container) {
    const currentUser = container.lookup("service:current-user");
    if (!currentUser?.admin) {
      return;
    }

    withPluginApi((api) => {
      api.setAdminPluginIcon("discourse-darkvisitors", "user-secret");
    });
  },
};
