module Openfoodnetwork
  class Application < Rails::Application
    config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
      r301 '/admin/products/bulk_edit', '/admin/products'

      # Old versions of our search forms generated parameter names with a
      # leading bracket like `[q][s]`. Rails deprecated parsing them but they
      # live on in bookmarks and search engine indexes.
      # We redirect to the correct name `q[s]` before Rails parses the params.
      leading_bracket = /(?<=\A|&)(?:%5B|\[)([^&=]+?)(?:%5D|\])/i
      r301(
        %r{\?(?:.*&)?(?:%5B|\[)}i,
        lambda do |_match, env|
          query = env["QUERY_STRING"].gsub(leading_bracket, '\1')
          "#{env['SCRIPT_NAME']}#{env['PATH_INFO']}?#{query}"
        end,
        if: ->(env) { env["REQUEST_METHOD"].in?(%w[GET HEAD]) },
      )
    end
  end
end
