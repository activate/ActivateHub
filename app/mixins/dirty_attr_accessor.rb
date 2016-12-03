# This module allows an ActiveModel object to track the dirtyness of
# non-persistent instance variables using ActiveModel::Dirty methods.
#

module DirtyAttrAccessor
  extend ActiveSupport::Concern

  module ClassMethods
    def dirty_attr_accessor(*attr_names)
      attr_reader *attr_names

      attr_names.map(&:to_s).each do |attr_name|
        define_method("#{attr_name}=") do |value|
          if changed_attributes[attr_name] == value
            # reverting to original value
            # Instance var hacks around internal changes in rails 4.2
            @changed_attributes.delete(attr_name)
          elsif instance_variable_get("@#{attr_name}") != value
            send("#{attr_name}_will_change!")
          end

          instance_variable_set("@#{attr_name}", value)
        end

        #---[ ActiveModel::Dirty Attibute Methods ]-------------------------
        # For dirty attr methods, it should be possible to write something
        # like the following (see rubydoc for ActiveModel::AttributeMethods):
        #   attr_accessor :attr1, :attr2
        #
        #   # automatically mixed in from ActiveModel::Dirty
        #   # attribute_method_suffix '_changed?', '_change', '_will_change!', '_was'
        #
        #   define_attribute_methods [:attr1, :attr2]
        #
        # Unfortunately `define_attribute_methods` doesn't work for non-AR attrs
        # because there are ActiveRecord-specific prefix/affix/suffix definitions
        # that assume any attributes passed to them are real ActiveRecord columns.

        define_method("restore_#{attr_name}!") { restore_attribute!(attr_name) }
        define_method("#{attr_name}_change") { attribute_change(attr_name) }
        define_method("#{attr_name}_changed?") { attribute_changed?(attr_name) }
        define_method("#{attr_name}_will_change!") { attribute_will_change!(attr_name) }
        define_method("#{attr_name}_was") { attribute_was(attr_name) }
      end
    end

  end
end
