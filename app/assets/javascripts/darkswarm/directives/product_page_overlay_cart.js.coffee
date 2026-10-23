# Lets the add to cart widgets of a product page shown over the product list (see
# product_page_overlay_controller.js) work with the shop's cart.
#
# The shop's cart saves all its line items at once, so it has to know about every change.
# The widgets ask it for their quantity when they appear and leave their changes to it.
angular.module('Darkswarm').directive "productPageOverlayCart", (Cart, Variants) ->
  restrict: "A"
  link: (scope, element) ->
    lineItemOf = (event) ->
      Variants.variants[event.detail.variantId]?.line_item

    element[0].addEventListener "add-to-cart:connect", (event) ->
      line_item = lineItemOf(event)
      event.detail.quantity = line_item.quantity || 0 if line_item?

    element[0].addEventListener "add-to-cart:change", (event) ->
      line_item = lineItemOf(event)
      return unless line_item?

      event.preventDefault()
      scope.$apply ->
        line_item.quantity = event.detail.quantity
        line_item.max_quantity = line_item.quantity if line_item.max_quantity < line_item.quantity
        Cart.adjust(line_item)
