# This module allows an ActiveRecord object to rebase any changed attributes
# on top of another object of the same class or with similar attribute names.
#
# "What attributes changed between X and Y?"
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
#
#   sports_coupe.changes # => { "color" => ["tan", "black"], "doors" => [4, 2], "price" => [9000, 25000] }
#   the_red_one.changes # => { "color" => ["black", "red"], "price" => [25000, 65000] }
#

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
    # only want to rebase receiver's attributes that have changed so attributes
    # from parent won't get covered up by nil attributes that were never set.
    # receiver's :id is an exception as we never want to keep the parent's :id
    orig_attribute_changes = attributes.slice('id', *changed)

    # resets this object's attributes to be identical to parent's
    self.attributes = parent.attributes
    self.parent_keys_for_partial_write = changed_attributes.keys
    changed_attributes.clear

    # restore original attributes on top of parent attributes
    self.attributes = orig_attribute_changes

    self
  end

  # Rails 4 introduced partial writes on database insert, which conflicts with
  # this mixin's ability to rebase attributes and mark them as not changed;
  # attributes need to be marked as not changed to give feedback about what
  # attributes were modified from the parent we're rebasing onto. This works
  # around the issue by overriding the code that determines what fields have
  # changed from the database defaults used by the Dirty mixin.
  def keys_for_partial_write
    super | (@parent_keys_for_partial_write || [])
  end

  def parent_keys_for_partial_write=(keys)
    @parent_keys_for_partial_write = keys
  end

end
