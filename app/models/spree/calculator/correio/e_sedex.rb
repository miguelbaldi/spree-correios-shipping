class Spree::Calculator::Correio::ESedex < Spree::Calculator::Correio::Scaffold

  def self.services
    [:e_sedex, :e_sedex_prioritario, :e_sedex_express, :e_sedex_grupo_1, :e_sedex_grupo_2, :e_sedex_grupo_3]
  end
end
