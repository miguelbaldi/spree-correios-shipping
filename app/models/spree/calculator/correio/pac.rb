class Spree::Calculator::Correio::Pac < Spree::Calculator::Correio::Scaffold

  def services
    [:pac_com_contrato, :pac]
  end
end
