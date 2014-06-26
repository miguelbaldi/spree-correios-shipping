class Spree::Calculator::Correio::Pac < Spree::Calculator::Correio::Scaffold
  class << self
    def fallback_amount
      preferred_fallback_amount + preferred_default_box_price
    end

    def fallback_timing
      -1
    end
  end
end
