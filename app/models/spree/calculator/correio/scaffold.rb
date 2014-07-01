class Spree::Calculator::Correio::Scaffold < Spree::Calculator::Correio::Base
  class << self
    def fallback_amount
      nil
    end

    def fallback_timing
      nil
    end
    def key
      model_name.i18n_key
    end

    def description
      I18n.t("#{key}.description")
    end

    def service
      I18n.t("#{key}.service").to_sym
    end
  end
end
