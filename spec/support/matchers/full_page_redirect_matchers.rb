# frozen_string_literal: true

# Matches a Turbo Stream response sent by FullPageRedirects.
#
# Usage:
#
#     expect(response).to full_page_redirect_to admin_order_cycles_path
RSpec::Matchers.define :full_page_redirect_to do |expected|
  match do |response|
    @actual = full_page_redirect_location(response)
    next false if @actual.nil?

    expected_uri = URI(expected)
    actual_uri = URI(@actual)
    actual_uri = actual_uri.request_uri if expected_uri.relative?
    actual_uri.to_s == expected_uri.to_s
  end

  failure_message do
    if @actual
      "expected a full page redirect to #{expected} but it redirects to #{@actual}"
    else
      "expected a full page redirect to #{expected} but got:\n#{response.body}"
    end
  end

  def full_page_redirect_location(response)
    return unless response.media_type == Mime[:turbo_stream]

    stream = Nokogiri::HTML.fragment(response.body).at_css(
      'turbo-stream[action="redirect_to"][turbo="false"]'
    )
    stream&.[]("url")
  end
end
