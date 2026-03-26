require "fileutils"
require "minitest/autorun"
require "open3"

class SitePagesTest < Minitest::Test
  OUTPUT_DIR = File.expand_path("../tmp/test-site", __dir__)
  ROOT_DIR = File.expand_path("..", __dir__)

  def setup
    FileUtils.rm_rf(OUTPUT_DIR)

    stdout, stderr, status = Open3.capture3(
      "bundle",
      "exec",
      "jekyll",
      "build",
      "--destination",
      OUTPUT_DIR,
      chdir: ROOT_DIR
    )

    build_output = [stdout, stderr].reject(&:empty?).join("\n")
    assert status.success?, "Jekyll build failed:\n#{build_output}"
  end

  def test_generates_required_pages
    assert_path_exists "index.html"
    assert_path_exists "about/index.html"
    assert_path_exists "schedule/index.html"
  end

  def test_navbar_links_to_all_top_level_pages
    home_html = File.read(File.join(OUTPUT_DIR, "index.html"))

    assert_includes home_html, 'href="/"'
    assert_includes home_html, ">Home</a>"
    assert_includes home_html, 'href="/about/"'
    assert_includes home_html, ">About</a>"
    assert_includes home_html, 'href="/schedule/"'
    assert_includes home_html, ">Schedule</a>"
  end

  def test_left_sidebar_persists_across_all_pages
    [
      "index.html",
      "about/index.html",
      "schedule/index.html"
    ].each do |relative_path|
      page_html = File.read(File.join(OUTPUT_DIR, relative_path))

      assert_includes page_html, 'class="sidebar sticky"'
      assert_includes page_html, ">InQuanto School</a>"
    end
  end

  def test_current_nav_link_is_marked_active_on_each_page
    assert_active_nav_link "index.html", "Home"
    assert_active_nav_link "about/index.html", "About"
    assert_active_nav_link "schedule/index.html", "Schedule"
  end

  def test_schedule_page_includes_draft_timetable_content
    schedule_html = File.read(File.join(OUTPUT_DIR, "schedule/index.html"))

    assert_includes schedule_html, "Draft Timetable"
    assert_includes schedule_html, "Monday"
    assert_includes schedule_html, "L1: Quantum computing"
    assert_includes schedule_html, "W5: InQ computables and protocols"
    assert_includes schedule_html, "Workshop dinner"
  end

  def test_page_content_typography_uses_justified_text_and_paragraph_spacing
    css = File.read(File.join(OUTPUT_DIR, "assets/css/main.css"))

    assert_match(/\.page__content p,\.page__content li,\.page__content dl\{[^}]*text-align:justify;?/, css)
    assert_match(/\.page__content p\{[^}]*margin:0 0 1\.3em;?/, css)
  end

  def test_home_page_renders_body_copy_as_paragraphs
    home_html = File.read(File.join(OUTPUT_DIR, "index.html"))

    assert_includes home_html, "<p>The purpose of this school"
    assert_includes home_html, "<p>This will be a five day event"
    assert_includes home_html, "<p>This event is being run by Quantinuum"
  end

  private

  def assert_active_nav_link(relative_path, link_title)
    html = File.read(File.join(OUTPUT_DIR, relative_path))

    assert_match(/class="nav__link is-active"[^>]*>\s*#{Regexp.escape(link_title)}<\/a>/m, html)
  end

  def assert_path_exists(relative_path)
    full_path = File.join(OUTPUT_DIR, relative_path)
    assert File.exist?(full_path), "Expected #{relative_path} to exist in built site"
  end
end
