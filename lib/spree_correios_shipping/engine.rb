module Spree::CorreiosShipping
end
module SpreeCorreiosShippingExtension
  class Engine < Rails::Engine
    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/models/spree/calculator/**/base.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
    end

    config.autoload_paths += %W(#{config.root}/lib)
    config.to_prepare &method(:activate).to_proc

    initializer "spree_correios_shipping.register.calculators" do |app|
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/models/spree/calculator/**/*.rb")) do |c|
        Rails.env.production? ? require(c) : load(c)
      end
      app.config.spree.calculators.shipping_methods += Spree::Calculator::Correio::Scaffold.descendants
    end
  end

end
