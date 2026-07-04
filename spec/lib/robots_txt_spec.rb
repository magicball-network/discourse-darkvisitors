# frozen_string_literal: true

RSpec.describe DarkVisitors::RobotsTxt do
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
end
