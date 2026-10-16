# frozen_string_literal: true

RSpec.describe DiscourseDarkvisitors::RobotsTxt do
  before do
    SiteSetting.darkvisitors_access_token = "dummy"
    SiteSetting.darkvisitors_robots_txt_enabled = true
  end

  it "can parse a robots.txt" do
    SiteSetting.darkvisitors_robots_txt_path = "/path1|/path2"

    agents = described_class.parse_robots_txt(<<~EOF)
        # Comments
        # User-Agent: comment
        
        User-Agent: foo
        Disallow: /something

        user-agent: bar
        Disallow: /something
        Disallow: /else

        Sitemap: /sitemap.xml
        EOF

    expect(agents).to contain_exactly(
      { name: "foo", disallow: %w[/path1 /path2] },
      { name: "bar", disallow: %w[/path1 /path2] }
    )
  end

  it "adds new agents before the wildcard" do
    robots_info = {
      header: "# Header comment",
      agents: [
        { name: "foo", disallow: ["/foo"] },
        { name: "*", disallow: ["/wildcard"] }
      ]
    }
    new_agents = [{ name: "bar", disallow: ["/bar"] }]
    PluginStore.set(
      DiscourseDarkvisitors::PLUGIN_NAME,
      DiscourseDarkvisitors::ROBOTS_TXT,
      { last_update: DateTime.now.to_s, agents: new_agents }
    )

    described_class.on_robots_info(robots_info)

    expect(robots_info[:agents]).to eq(
      [
        { name: "foo", disallow: ["/foo"] },
        { name: "bar", disallow: ["/bar"] },
        { name: "*", disallow: ["/wildcard"] }
      ]
    )

    expect(robots_info[:header]).to include("Augmented by Known Agents")
  end

  it "adds new agents at the end if there is no wildcard" do
    robots_info = {
      header: "# Header comment",
      agents: [{ name: "foo", disallow: ["/foo"] }]
    }
    new_agents = [{ name: "bar", disallow: ["/bar"] }]
    PluginStore.set(
      DiscourseDarkvisitors::PLUGIN_NAME,
      DiscourseDarkvisitors::ROBOTS_TXT,
      { last_update: DateTime.now.to_s, agents: new_agents }
    )

    described_class.on_robots_info(robots_info)

    expect(robots_info[:agents]).to eq(
      [{ name: "foo", disallow: ["/foo"] }, { name: "bar", disallow: ["/bar"] }]
    )
  end
end
