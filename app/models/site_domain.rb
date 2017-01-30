class SiteDomain < ApplicationRecord

  belongs_to :site

  validates :domain,
    presence: true,
    uniqueness: { allow_blank: true, case_sensitive: false }

  validates :redirect,
    inclusion: { in: [ true, false ], message: :blank } # presence: true

  validates :site,
    presence: true

  def domain=(value)
    super(value.try(:downcase))
  end

end
