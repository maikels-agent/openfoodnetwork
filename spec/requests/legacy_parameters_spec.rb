# frozen_string_literal: true

RSpec.describe "Legacy parameter names" do
  it "redirects parameter names with leading brackets" do
    get "/admin/products?page=&per_page=15&%5Bq%5D%5Bs%5D=name+asc&search_term=apple"

    expect(response).to have_http_status(:moved_permanently)
    expect(response.location).to end_with(
      "/admin/products?page=&per_page=15&q%5Bs%5D=name+asc&search_term=apple"
    )
  end

  it "redirects unencoded leading brackets" do
    get "/admin/orders?[q][s]=completed_at+desc"

    expect(response).to have_http_status(:moved_permanently)
    expect(response.location).to end_with("/admin/orders?q[s]=completed_at+desc")
  end

  it "leaves regular parameter names alone" do
    get "/admin/products?q%5Bs%5D=name+asc&search_term=%5Bq%5D"

    expect(response).not_to have_http_status(:moved_permanently)
  end
end
