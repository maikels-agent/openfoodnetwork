# frozen_string_literal: true

RSpec.describe FullPageRedirects do
  controller(ApplicationController) do
    include FullPageRedirects

    def index
      redirect_to "/target"
    end

    def create
      redirect_to "/target", flash: { success: "Done" }
    end
  end

  describe "a GET request" do
    it "redirects as usual" do
      get :index

      expect(response).to have_http_status :found
      expect(response).to redirect_to "/target"
    end

    it "redirects Turbo as usual" do
      get :index, format: :turbo_stream

      expect(response).to have_http_status :found
      expect(response).to redirect_to "/target"
    end
  end

  describe "a non-GET request" do
    it "redirects with 303 See Other" do
      post :create

      expect(response).to have_http_status :see_other
      expect(response).to redirect_to "/target"
      expect(flash[:success]).to eq "Done"
    end

    it "keeps an explicit status" do
      controller.define_singleton_method(:create) do
        redirect_to "/target", status: :moved_permanently
      end

      post :create

      expect(response).to have_http_status :moved_permanently
    end

    it "tells Turbo to load the new page" do
      post :create, format: :turbo_stream

      expect(response).to have_http_status :ok
      expect(response.headers["Location"]).to be_nil
      expect(response).to full_page_redirect_to "/target"
      expect(flash[:success]).to eq "Done"
    end

    it "tells Turbo to load the new page when CableReady is preferred" do
      request.headers["Accept"] =
        "text/vnd.cable-ready.json, text/vnd.turbo-stream.html, text/html, application/xhtml+xml"

      post :create

      expect(response).to full_page_redirect_to "/target"
    end

    it "redirects a Turbo Frame with 303 See Other" do
      request.headers["Turbo-Frame"] = "modal"

      post :create, format: :turbo_stream

      expect(response).to have_http_status :see_other
      expect(response).to redirect_to "/target"
    end
  end
end
