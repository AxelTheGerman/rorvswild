require File.expand_path("#{File.dirname(__FILE__)}/../helper")

require "net/http"

class RorVsWild::Plugin::NetHttpTest < Minitest::Test
  include RorVsWild::AgentHelper

  def test_callback
    agent.measure_block("test") { Net::HTTP.get("www.ruby-lang.org", "/index.html") }
    sections = current_sections_without_gc
    assert_equal(1, sections.size)
    assert_equal(1, sections[0].calls)
    assert_equal("http", sections[0].kind)
    assert_match("GET www.ruby-lang.org", sections[0].command)
  end

  def test_callback_with_https
    agent.measure_block("test") { Net::HTTP.get(URI("https://www.ruby-lang.org/index.html")) }
    sections = current_sections_without_gc
    assert_match("GET www.ruby-lang.org", sections[0].command)
    assert_equal("http", sections[0].kind)
  end

  def test_nested_query_because_net_http_request_is_recursive_when_connection_is_not_started
    agent.measure_block("test") do
      uri = URI("http://www.ruby-lang.org/index.html")
      http = Net::HTTP.new(uri.host, uri.port)
      http.request(Net::HTTP::Get.new(uri.path))
    end
    sections = current_sections_without_gc
    assert_equal(1, sections[0].calls)
  end
end
