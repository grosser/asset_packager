require 'test/test_helper'

class CssCompressionTest < ActionController::TestCase
  def compress_css(css)
    Synthesis::AssetPackage.send(:compress_css, css)
  end

  def setup
    Rails.env = 'development'
    Synthesis::AssetPackage.asset_packages_yml = {}
  end

  def options(x)
    Synthesis::AssetPackage.asset_packages_yml = {'options' => x}
  end

  def teardown
    `rm -rf #{fake_path}`
  end

  def write(path, stuff)
    path = fake_path(path)
    `mkdir -p #{File.dirname(path)}`
    File.open(path,'w'){|f| f.write(stuff) }
  end

  def fake_path(path=nil)
    "test/fake_root/#{path}"
  end

  # ENVIRONMENTS
  test "reads from default environment" do
    options('default' => {'bla' => 1})
    assert_equal({'bla' => 1}, Synthesis::AssetPackage.asset_packages_options)
  end

  test "reads from empty environment" do
    options('bla' => 1)
    assert_equal({'bla' => 1}, Synthesis::AssetPackage.asset_packages_options)
  end

  test "reads from current environment" do
    Rails.env = 'test'
    options('test' => {'bla' => 1})
    assert_equal({'bla' => 1}, Synthesis::AssetPackage.asset_packages_options)
  end

  # TIMESTAMP
  test "does not add timestamps to urls when option is not set" do
    write('public/foo.jpg','x')
    assert_equal compress_css("url(/foo.jpg)"), "url(/foo.jpg)"
  end

  test "adds timestamps to urls" do
    options 'add_timestamps_to_css_urls' => true
    write('public/foo.jpg','x')
    assert_equal compress_css("url(/foo.jpg)"), "url(/foo.jpg?#{Time.now.to_i})"
  end

  test "adds timestamps to urls with ' or '' " do
    options 'add_timestamps_to_css_urls' => true
    write('public/foo.jpg','x')
    assert_equal compress_css(%{url('/foo.jpg');url("/foo.jpg")}), %{url('/foo.jpg?#{Time.now.to_i}');url("/foo.jpg?#{Time.now.to_i}")}
  end

  test "does not add timestamps to strange urls" do
    options 'add_timestamps_to_css_urls' => true
    write('public/foo.bla','x')
    assert_equal compress_css(%{url(/foo.bla)}), %{url(/foo.bla)}
  end

  test "does not add timestamps to unfound urls" do
    options 'add_timestamps_to_css_urls' => true
    assert_equal compress_css(%{url(/foo.jpg)}), %{url(/foo.jpg)}
  end

  test "adds timestamps to local+relative urls" do
    options 'add_timestamps_to_css_urls' => true
    write('public/stylesheets/foo.jpg','x')
    assert_equal compress_css(%{url(foo.jpg)}), %{url(foo.jpg?#{Time.now.to_i})}
  end

  test "does not add timestamps to remote urls" do
    options 'add_timestamps_to_css_urls' => true
    write('public/foo.jpg','x')
    write('public/stylesheets/foo.jpg','x')
    assert_equal compress_css(%{url(http://foo.com/foo.jpg)}), %{url(http://foo.com/foo.jpg)}
  end

  # ASSET HOST
  test "adds asset_host to local urls" do
    options 'asset_host' => 'http://bar'
    assert_equal %{url(http://bar/foo.jpg)}, compress_css(%{url(/foo.jpg)})
  end

  test "adds asset_host to local relative urls" do
    options 'asset_host' => 'http://bar'
    assert_equal %{url(http://bar/stylesheets/foo.jpg)}, compress_css(%{url(foo.jpg)})
  end

  test "adds timestamp and host" do
    options 'asset_host' => 'http://bar', 'add_timestamps_to_css_urls' => true
    write('public/foo.jpg','x')
    assert_equal %{url(http://bar/foo.jpg?#{Time.now.to_i})}, compress_css(%{url(/foo.jpg)})
  end

  test "does not add asset host to remote urls" do
    options 'asset_host' => 'http://bar'
    assert_equal %{url(http://a.b/foo.jpg)}, compress_css(%{url(http://a.b/foo.jpg)})
  end
end