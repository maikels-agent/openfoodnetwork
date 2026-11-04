# frozen_string_literal: true

# Redirect after a non-GET request with a full page load.
#
# Turbo submits forms and `data-turbo-method` links with fetch and follows the
# redirect within that request. It then swaps the page body without loading the
# page. AngularJS apps don't start on such a page and the flash message has
# already been consumed by the followed redirect.
#
# Instead, we answer Turbo with a stream action telling the browser to visit the
# location. That's a normal page load which shows the flash and starts AngularJS.
#
# All other non-GET requests are redirected with 303 See Other. A 302 would let
# Turbo and other fetch clients repeat a PUT, PATCH or DELETE request at the new
# location.
module FullPageRedirects
  def redirect_to(options = {}, response_options = {})
    return super if request.get? || request.head?
    return super(options, { status: :see_other }.merge(response_options)) unless turbo_page_request?

    # Let Rails resolve the location and set the flash, then replace the redirect.
    super
    location = response.headers.delete("Location")
    self.status = :ok
    self.content_type = Mime[:turbo_stream]
    self.response_body = turbo_stream.redirect_to(location, turbo: false)
  end

  private

  # Turbo accepts streams for all non-GET requests but our CableReady
  # integration may add another preferred format.
  # Turbo Frames load their content with fetch, not with a page visit.
  def turbo_page_request?
    request.formats.include?(Mime[:turbo_stream]) && !turbo_frame_request?
  end
end
