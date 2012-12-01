module Spree
  class Calculator::Correio::Base < Calculator
    def cached_response(order)
      response = Rails.cache.fetch(cache_key(order)) do
        response = correio_info(order)
      end
      response
    end

    def compute(object)
      order = find_order(object)
      response_for_service = cached_response(order)[self.class.service]
      return self.class.fallback_amount if response_for_service.blank? || response_for_service.error?
      cached_response(order)[self.class.service].valor + Spree::CorreiosShipping::Config[:default_box_price] rescue nil
    end
    
    def timing(object)
      order = find_order(object)
      response_for_service = cached_response(order)[self.class.service]
      return self.class.fallback_timing if response_for_service.blank? || response_for_service.error?
      cached_response(order)[self.class.service].prazo_entrega
    end

    private
    
    def correio_info(order)
      total_weight = order_total_weight(order)
      return {} if total_weight == 0

      request_attributes = {
        :cep_origem => Spree::CorreiosShipping::Config[:zipcode],
        :cep_destino => order.ship_address.zipcode.to_s,
        :peso => total_weight,
        :comprimento => Spree::CorreiosShipping::Config[:box_x],
        :largura => Spree::CorreiosShipping::Config[:box_y],
        :altura => Spree::CorreiosShipping::Config[:box_z],
      }
      request = Correios::Frete::Calculador.new request_attributes
      
      begin
        response = request.calcular *Spree::Calculator::Correio::Scaffold.descendants.map(&:service)
      rescue
        fake_service = OpenStruct.new(valor: Spree::CorreiosShipping::Config[:fallback_amount], prazo_entrega: -1)
        response = {:pac => fake_service}
      end
      response
    end
    
    def error_list
      ["-3", "-6", "-10", "-33", "-888", "006", "7", "99"]
    end
    
    def no_service?(response)
      response.values.select{|v| v.error?}.count == response.values.count
    end
    
    def catch_errors(response)
      errors = []
      response.values.each do |v|
        errors << v.msg_erro if v.erro.in?(error_list)
      end
      errors.uniq.join(", ")
    end

    def order_total_weight(order)
      weight = 0
      order.line_items.each do |item|
        weight += item.quantity * (item.variant.weight || 0)
      end
      weight == 0 ? Spree::CorreiosShipping::Config[:default_weight] : weight
    end

    def find_order(object)
      if object.is_a?(Array)
        order = object.first.order
      elsif object.is_a?(Shipment)
        order = object.order
      else
        order = object
      end
      order
    end
    
    def cache_key(order)
      addr = order.ship_address
      line_items_hash = Digest::MD5.hexdigest(order.line_items.map {|li| li.variant_id.to_s + "_" + li.quantity.to_s }.join("|"))
      @cache_key = "correio-#{order.number}-#{addr.country.iso}-#{addr.state ? addr.state.abbr : addr.state_name}-#{addr.city}-#{addr.zipcode}-#{line_items_hash}".gsub(" ","")
    end
  end
end
