class SiteDomain < ApplicationRecord

  belongs_to :site

  validates :domain,
    presence: true,
    uniqueness: { allow_blank: true }

  validates :redirect,
    inclusion: { in: [ true, false ], message: :blank } # presence: true

  validates :site,
    presence: true

end
