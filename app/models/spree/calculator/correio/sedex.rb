class Spree::Calculator::Correio::Sedex < Spree::Calculator::Correio::Scaffold

  def services
    [:sedex_com_contrato_1, :sedex_com_contrato_2, :sedex_com_contrato_3, :sedex_com_contrato_4, :sedex_com_contrato_5, :sedex]
  end
end
