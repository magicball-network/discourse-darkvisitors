# frozen_string_literal: true

RSpec.describe DiscourseDarkvisitors::ServerAnalytics do
  before { SiteSetting.darkvisitors_access_token = "dummy" }

  it "is disabled" do
    action = Scheduler::Defer.stubs(:later)
    described_class.log_request({}, {})
    action.never
  end

  it "tracks anonymous only" do
    SiteSetting.darkvisitors_server_analytics = "anonymous_only"

    action = Scheduler::Defer.stubs(:later)
    env = { "REQUEST_PATH" => "/", "HTTP_USER_AGENT" => "Test" }
    data = { track_view: true, has_auth_cookie: true }
    described_class.log_request(env, data)
    action.never

    action = Scheduler::Defer.stubs(:later)
    data = { track_view: true, has_auth_cookie: false }
    described_class.log_request(env, data)
    action.once
  end

  it "does not track background/api-calls" do
    SiteSetting.darkvisitors_server_analytics = "enabled"

    action = Scheduler::Defer.stubs(:later)
    env = { "REQUEST_PATH" => "/", "HTTP_USER_AGENT" => "Test" }
    data = { track_view: true, is_background: true }
    described_class.log_request(env, data)
    data = { track_view: true, is_api: true }
    described_class.log_request(env, data)
    data = { track_view: true, is_user_api: true }
    described_class.log_request(env, data)
    action.never

    action = Scheduler::Defer.stubs(:later)
    data = { track_view: true }
    described_class.log_request(env, data)
    action.once
  end

  it "does not track background/api-calls" do
    SiteSetting.darkvisitors_server_analytics = "enabled"

    action = described_class.stubs(:report_visit)
    env = {
      "REQUEST_PATH" => "/",
      "REQUEST_METHOD" => "GET",
      "HTTP_USER_AGENT" => "Test-User-Agent",
      "HTTP_ACCEPT" => "text/*"
    }
    data = { track_view: true, request_remote_ip: "127.0.0.1" }
    described_class.log_request(env, data)

    action
      .once
      .with() do |value|
        expect(value.request_path).to eq "/"
        expect(value.request_method).to eq "GET"
        expect(value.headers["User-Agent"]).to eq "Test-User-Agent"
        expect(value.headers["Remote-Addr"]).to eq "127.0.0.1"
        expect(value.headers["Accept"]).to eq "text/*"
      end
  end

  it "makes a relative path" do
    env = { "REQUEST_PATH" => "/somepath" }
    expect(described_class.relative_request_path(env)).to eq "/somepath"

    env = { "REQUEST_PATH" => "/basepath/somepath" }
    ActionController::Base.config.relative_url_root = "/basepath"
    expect(described_class.relative_request_path(env)).to eq "/somepath"
  end

  it "should ignore admin paths" do
    expect(
      described_class.ignore_path("/admin/something/in/the/admin-ui")
    ).to be true
  end

  it "should by default only track tracked request" do
    SiteSetting.darkvisitors_server_analytics_include = ""
    data = { track_view: true }
    expect(described_class.should_track(data, "/")).to be true
    data = { track_view: false }
    expect(described_class.should_track(data, "/")).to be false
  end

  #it "should track everything" do
  #  SiteSetting.darkvisitors_server_analytics_include = "everything"
  #  expect(DarkVisitors::ServerAnalytics.should_track({}, "/asd")).to be true
  #end

  it "should track not found" do
    SiteSetting.darkvisitors_server_analytics_include = "not_found"
    data = { track_view: false, status: 404 }
    expect(described_class.should_track(data, "/")).to be true
    data = { track_view: false, status: 200 }
    expect(described_class.should_track(data, "/")).to be false
  end

  it "should track uploads" do
    SiteSetting.darkvisitors_server_analytics_include = "uploads"
    data = { track_view: false, status: 200 }
    expect(described_class.should_track(data, "/uploads/foobar")).to be true
    data = { track_view: false, status: 404 }
    expect(described_class.should_track(data, "/uploads/foobar")).to be false
  end

  it "does not ignore a blank ignore setting" do
    SiteSetting.darkvisitors_server_analytics_ignore = ""
    should_ignore = described_class.ignore_user_agent("Test-User-Agent")
    expect(should_ignore).to be false
  end

  it "ignores a configured user agent" do
    SiteSetting.darkvisitors_server_analytics_ignore = "update-agent|ignore-me"
    should_ignore =
      described_class.ignore_user_agent(
        "Test-User-Agent/1.0 (compatible; ignore-me) 202505062029"
      )
    expect(should_ignore).to be true
    should_ignore =
      described_class.ignore_user_agent(
        "Test-User-Agent/1.0 (compatible) 202505062029"
      )
    expect(should_ignore).to be false
  end
end
