# US address filter for geographic filterable resources.
# @see GeographicFilter
class AddressFilter < GeographicFilter
  include StateFieldValidations

  before_validation { self.address = address&.strip&.upcase }
  before_validation { self.city = city&.strip&.upcase }
  before_validation { self.zipcode = zipcode&.strip }

  validates_presence_of :address, :city
  validates :zipcode,
    presence: true,
    format: {with: /\A\d{5}\z/}

  def line
    state_and_zipcode = [state, zipcode].reject(&:blank?).join(" ")
    [address, city, state_and_zipcode].reject(&:blank?).join(", ")
  end
end
