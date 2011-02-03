require 'test/test_helper'

class CssCompressionTest < ActionController::TestCase
  def compress_css(css)
    Synthesis::AssetPackage.send(:compress_css, css)
  end

  def setup
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

  # TIMESTAMP
  test "adds timestamps to urls" do
    write('public/foo.jpg','x')
    assert_equal compress_css("url(/foo.jpg)"), "url(/foo.jpg?#{Time.now.to_i})"
  end

  test "adds timestamps to urls with ' or '' " do
    write('public/foo.jpg','x')
    assert_equal compress_css(%{url('/foo.jpg');url("/foo.jpg")}), %{url('/foo.jpg?#{Time.now.to_i}');url("/foo.jpg?#{Time.now.to_i}")}
  end

  test "does not add timestamps to strange urls" do
    write('public/foo.bla','x')
    assert_equal compress_css(%{url(/foo.bla)}), %{url(/foo.bla)}
  end

  test "does not add timestamps to unfound urls" do
    assert_equal compress_css(%{url(/foo.jpg)}), %{url(/foo.jpg)}
  end

  test "adds timestamps to local+relative urls" do
    write('public/stylesheets/foo.jpg','x')
    assert_equal compress_css(%{url(foo.jpg)}), %{url(foo.jpg?#{Time.now.to_i})}
  end

  test "does not add timestamps to remote urls" do
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
    options 'asset_host' => 'http://bar'
    write('public/foo.jpg','x')
    assert_equal %{url(http://bar/foo.jpg?#{Time.now.to_i})}, compress_css(%{url(/foo.jpg)})
  end

  test "does not add asset host to remote urls" do
    options 'asset_host' => 'http://bar'
    assert_equal %{url(http://a.b/foo.jpg)}, compress_css(%{url(http://a.b/foo.jpg)})
  end
end