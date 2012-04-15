module Spree
  class Calculator::Correio::Base < Calculator
    preference :zipcode, :string
    preference :default_weight, :decimal, :default => 0.0
    preference :box_x, :integer, :default => 36
    preference :box_y, :integer, :default => 27
    preference :box_z, :integer, :default => 27
    preference :notice, :boolean, :default => false
    preference :warranty, :boolean, :default => false
    
    def cached_response(order)
      response = Rails.cache.fetch(cache_key(order)) do
        response = correio_info(order)
      end
      response
    end

    def compute(object)
      order = find_order(object)
      response_for_service = cached_response(order)[self.class.service]
      cached_response(order)[self.class.service].valor rescue nil
    end
    
    def timing(object)
      order = find_order(object)
      cached_response(order)[self.class.service].prazo_entrega rescue nil
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
        :aviso_recebimento => preferred_notice
      }
      total_cost_price = if preferred_warranty
        begin
          order.total_cost_price 
        rescue
          raise "Spree::Order#total_cost_price must be implemented"
        end
      end
      
      request_attributes.merge!(:valor_declarado => order.total_cost_price) if total_cost_price
      
      request = Correios::Frete::Calculador.new request_attributes
      
      begin
        response = request.calcular :sedex, :pac, :e_sedex, :sedex_10, :sedex_hoje
      rescue => e
        raise "my error"
      end
    end

    def order_total_weight(order)
      total_weight = 0
      order.line_items.each do |item|
        total_weight += item.quantity * (item.variant.weight || self.preferred_default_weight)
      end
      total_weight
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
