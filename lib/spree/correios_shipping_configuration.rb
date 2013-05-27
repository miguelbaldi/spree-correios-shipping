class Spree::CorreiosShippingConfiguration < Spree::Preferences::Configuration
  preference :zipcode, :string
  preference :default_weight, :decimal, :default => 0.0
  preference :default_box_weight, :decimal, :default => 0.25
  preference :default_box_price, :decimal, :default => 0.0
  preference :fallback_amount, :decimal, :default => 14.9
  preference :box_x, :integer, :default => 36
  preference :box_y, :integer, :default => 27
  preference :box_z, :integer, :default => 27
  # Not used for now
  preference :warranty_on_frontend, :boolean, :default => false
  preference :warranty_on_frontend, :boolean, :default => false
  preference :warranty_on_backend, :boolean, :default => true
  preference :notice_on_backend, :boolean, :default => false
end
