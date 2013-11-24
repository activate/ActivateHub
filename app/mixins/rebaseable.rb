# This module allows an ActiveRecord object to rebase any changed attributes
# on top of another object of the same class or with similar attribute names.
#
# "I want X to be like Y, except ..."
#
# @example
#   sedan = Car.new(:model => 'XRC-9D', :color => 'tan', :doors => 4, :price => 9_000)
#
#   sports_coupe = Car.new(:color => 'black', :doors => 2, :price => 25_000)
#   sports_coupe.rebase_changed_attributes!(sedan)
#   # => { :model => 'XRC-9D', :color => 'black', :doors => 2, :price => 25_000 }
#
#   the_red_one = Car.new(:color => 'red', :price => 65_000)
#   the_red_one.rebase_changed_attributes!(sports_coupe)
#   # => { :model => 'XRC-9D', :color => 'red', :doors => 2, :price => 65_000 }

module Rebaseable
  extend ActiveSupport::Concern

  def rebase_changed_attributes(parent)
    self.dup.rebase_changed_attributes!(parent)
  end

  # Rebases receiver's changed attributes on top of parent's attributes.
  # Similar in to Rails' +Hash#reverse_merge!+, but for model objects.
  # Modifies the receiver in place.
  #
  # Updates +changed_attributes+ so ActiveModel::Dirty (_changed?, _was?, etc)
  # reflects any changes made between the parent and the receiver.
  #
  # @param parent any model object with a subset of receiver's attributes
  # @return The object being invoked against (self)
  def rebase_changed_attributes!(parent)
    # we only care about rebasing attributes that were explictly changed,
    # otherwise we'd overwrite important data in parent like venue_id
    orig_attribute_changes = attributes.slice(*changed)

    # resets this object's attributes to be identical to parent
    self.attributes = parent.attributes #.except(:id)
    changed_attributes.clear

    # apply our original attributes on top, allowing us to identify changes
    self.attributes = orig_attribute_changes

    self
  end

end
