# frozen_string_literal: true

# Visual regression testing: compare a screenshot of the current page with a
# committed baseline image.
#
#   RSpec.describe "Shopfront", :visual do
#     it "looks the same" do
#       visit enterprise_shop_path(shop)
#       expect_visual_match "shopfront/products", mask: [".order-number"]
#     end
#   end
#
# Baselines live in spec/fixtures/visual/. A missing baseline is recorded on the
# first run (and fails on CI). Re-record after an intended UI change with:
#
#   VISUAL_RECORD=1 bundle exec rspec spec/system/visual
#
# Font rendering differs between operating systems. Record baselines in the same
# environment that compares them (CI), otherwise every image will differ.
module VisualRegression
  BASELINE_DIR = Rails.root.join("spec/fixtures/visual")

  # Per-pixel colour difference ignored as anti-aliasing noise.
  # Without it, repeated renderings of the same page differ in a few faint pixels.
  FUZZ = "2%"

  # Number of differing pixels (beyond the fuzz) still accepted as a match.
  # Keep it absolute, not a percentage: a changed price is only ~200 pixels,
  # which is 0.02% of a 1280x800 screenshot.
  TOLERANCE = 0

  # The time seen by the server and the browser in visual specs.
  FROZEN_TIME = "2030-01-15 10:00:00"

  # Neutralise everything that changes between two renderings of the same page.
  STABLE_CSS = <<~CSS
    *, *::before, *::after {
      animation: none !important;
      transition: none !important;
      caret-color: transparent !important;
      scroll-behavior: auto !important;
    }
    ::-webkit-scrollbar { display: none !important; }
    [data-visual-mask] { visibility: hidden !important; }
  CSS

  def expect_visual_match(name, mask: [], tolerance: TOLERANCE)
    stabilise_page(mask)

    baseline = BASELINE_DIR.join("#{name}.png")
    current = artifact_path(name, "current")
    page.driver.save_screenshot(current.to_s, full: false)

    if ENV["VISUAL_RECORD"] || !baseline.exist?
      record_baseline(baseline, current)
    else
      compare_with_baseline(baseline, current, artifact_path(name, "diff"), tolerance)
    end
  end

  private

  def stabilise_page(mask)
    page.driver.wait_for_network_idle
    page.execute_script(<<~JS, STABLE_CSS, mask)
      const [css, mask] = arguments;
      const style = document.createElement("style");
      style.textContent = css;
      document.head.appendChild(style);
      mask.forEach((selector) => {
        document.querySelectorAll(selector).forEach((el) => {
          el.setAttribute("data-visual-mask", "");
        });
      });
      document.activeElement?.blur();
      window.scrollTo(0, 0);
    JS
    page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      const images = Array.from(document.images).filter((img) => !img.complete);
      const loaded = images.map((img) => new Promise((resolve) => {
        img.addEventListener("load", resolve);
        img.addEventListener("error", resolve);
      }));
      Promise.all([document.fonts.ready, ...loaded])
        .then(() => requestAnimationFrame(() => requestAnimationFrame(done)));
    JS
  end

  def record_baseline(baseline, current)
    if ENV["CI"]
      raise "Missing visual baseline #{baseline}. " \
            "Download #{current.basename} from the CI artifacts or record it with VISUAL_RECORD=1."
    end

    FileUtils.mkdir_p(baseline.dirname)
    FileUtils.cp(current, baseline)
  end

  def compare_with_baseline(baseline, current, diff, tolerance)
    expected = MiniMagick::Image.open(baseline)
    actual = MiniMagick::Image.open(current)

    if expected.dimensions != actual.dimensions
      raise RSpec::Expectations::ExpectationNotMetError,
            "Screenshot size #{actual.dimensions} differs from baseline " \
            "#{expected.dimensions}.\nBaseline: #{baseline}\nCurrent:  #{current}"
    end

    different = count_different_pixels(baseline, current, diff)
    return FileUtils.rm_f(diff) if different <= tolerance

    raise RSpec::Expectations::ExpectationNotMetError,
          "Screenshot differs from baseline in #{different} pixels.\n" \
          "Baseline: #{baseline}\nCurrent:  #{current}\nDiff:     #{diff}\n" \
          "If the change is intended, replace the baseline with the current image."
  end

  # `compare -metric AE` prints the number of differing pixels to stderr
  # and exits with 1 when the images differ, so we can't treat that as an error.
  def count_different_pixels(baseline, current, diff)
    compare = MiniMagick::Tool.new("compare", errors: false)
    compare.metric("AE")
    compare.fuzz(FUZZ)
    compare << baseline.to_s << current.to_s << diff.to_s
    compare.call do |_stdout, stderr, _status|
      # ImageMagick 7 prints "123 (0.0012)", ImageMagick 6 prints "123".
      return Float(stderr.split.first).to_i
    end
  end

  def artifact_path(name, suffix)
    path = Pathname.new(Capybara.save_path).join("visual", "#{name}.#{suffix}.png")
    FileUtils.mkdir_p(path.dirname)
    path
  end
end

RSpec.configure do |config|
  config.include VisualRegression, :visual

  # Make the page content independent of the run order and the current date.
  config.around(:each, :visual) do |example|
    FactoryBot.rewind_sequences
    FFaker::Random.seed = 1
    Kernel.srand(1)

    time = Time.zone.parse(VisualRegression::FROZEN_TIME)
    browser_page = page.driver.browser.page
    browser_page.command("Emulation.setTimezoneOverride", timezoneId: Time.zone.tzinfo.name)
    # Shift the browser clock to the frozen time but let it tick: timers keep working.
    browser_page.command(
      "Page.addScriptToEvaluateOnNewDocument",
      source: <<~JS
        (() => {
          const RealDate = Date;
          const offset = #{(time.to_f * 1000).to_i} - RealDate.now();
          class FrozenDate extends RealDate {
            constructor(...args) {
              args.length ? super(...args) : super(RealDate.now() + offset);
            }
            static now() { return RealDate.now() + offset; }
          }
          window.Date = FrozenDate;
        })();
      JS
    )

    travel_to(time) { example.run }
  end
end
