module Spree
  class Calculator::Correio::Base < Spree::ShippingCalculator
    preference :zipcode, :string
    preference :default_weight, :decimal, :default => 0.0
    preference :default_box_weight, :decimal, :default => 0.25
    preference :default_box_price, :decimal, :default => 0.0
    preference :box_x, :integer, :default => 36
    preference :box_y, :integer, :default => 27
    preference :box_z, :integer, :default => 27
    preference :company_code, :string
    preference :password, :string

    def cached_response(order)
      # response = Rails.cache.fetch(cache_key(order)) do
        response = correio_info(order)
      # end
      response
    end

    def compute(object)
      begin
        order = find_order(object)
        response_for_service = cached_response(order).select{ |d| services.include?(d) }.reject{ |k,v| v.error? }
                               .values.min_by(&:valor)
        response_for_service.valor + preferred_default_box_price
      rescue
        nil
      end
    end

    def timing(object)
      begin
        order = find_order(object)
        response_for_service = cached_response(order).select{ |d| services.include?(d) }.reject{ |k,v| v.error? }
                                 .values.min_by(&:valor)
        response_for_service.prazo_entrega
      rescue
        nil
      end
    end

    private
    def correio_info(order)
      total_weight = order_total_weight(order)
      return {} if total_weight == 0

      request_attributes = {
        :cep_origem => preferred_zipcode,
        :cep_destino => order.ship_address.zipcode.to_s,
        :peso => total_weight,
        :comprimento => preferred_box_x,
        :largura => preferred_box_y,
        :altura => preferred_box_z,
      }

      if has_preference? :company_code and has_preference? :password
        request_attributes[:codigo_empresa] = preferred_company_code unless preferred_company_code.blank?
        request_attributes[:senha] = preferred_password unless preferred_password.blank?
      end

      request = Correios::Frete::Calculador.new request_attributes

      begin
        response = request.calcular *available_services
      rescue
        fake_service = OpenStruct.new(valor: preferred_fallback_amount, prazo_entrega: -1)
        response = {:pac => fake_service}
      end

      response
    end

    def order_total_weight(order)
      weight = preferred_default_box_weight || 0
      order.line_items.each do |item|
        weight += item.quantity * (item.variant.weight || 0)
      end
      weight == 0 ? preferred_default_weight : weight
    end

    def find_order(object)
      if object.is_a?(Array)
        order = object.first.order
      elsif object.is_a?(Shipment)
        order = object.order
      elsif object.is_a?(Spree::Stock::Package)
        order = object.order
      else
        order = object
      end
      order
    end

    def cache_key(order)
      addr = order.ship_address
      line_items_hash = Digest::MD5.hexdigest(order.line_items.map {|li| li.variant_id.to_s + "_" + li.quantity.to_s }.join("|"))
      credentials = "#{preferred_company_code}-#{preferred_password}"
      @cache_key = "correio-#{order.number}-#{addr.country.iso}-#{addr.state ? addr.state.abbr : addr.state_name}-#{addr.city}-#{addr.zipcode}-#{line_items_hash}-#{credentials}-#{preferred_zipcode}".gsub(" ","")
    end

    def available_services
      Spree::Calculator.where(type: available_calculators_class_name).map(&:services).flatten
    end

    def available_calculators_class_name
      Spree::Calculator::Correio::Scaffold.descendants.map(&:name)
    end

  end
end
