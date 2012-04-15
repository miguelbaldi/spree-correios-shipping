# handle shipping errors gracefully on admin ui
Spree::Admin::ShipmentsController.class_eval do
  rescue_from Spree::CorreiosShippingError, :with => :handle_shipping_error

  private
    def handle_shipping_error(e)
      load_object
      flash.now[:error] = e.message
      render :action => "edit"
    end
end