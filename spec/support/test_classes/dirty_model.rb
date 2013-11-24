# A minimum ActiveModel-based class that implements ActiveModel::Dirty
# behavior in a way that is consistent with ActiveRecord, but does not
# require ActiveRecord::Base or a known database table.

module TestClasses
  # To use, subclass TestClasses::DirtyModel and then define your attributes.
  #
  # @example
  #   class MyTestModel < TestClasses::DirtyModel
  #     define_attributes :foo, :bar, :baz
  #   end
  #
  #   obj = MyTestModel.new(:foo => 'abc')
  #   obj.bar = 'def'
  #   obj.attributes = { 'baz' => 'ghi' }
  #   obj.attributes # => { 'foo' => 'abc', 'bar' => 'def', 'baz' => 'ghi' }
  #   obj.changes # => {"foo"=>[nil, "abc"], "bar"=>[nil, "def"], "baz"=>[nil, "ghi"]}
  class DirtyModel
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty

    # A lot of magic happens inside of ActiveModel::AttributeMethods that
    # provides getters setters for all attributes with keys defined in
    # +@attributes+, eventually calling +attribute+ and +attribute=+.

    # Defined in ActiveRecord::AttributeMethods::Write
    attribute_method_suffix '='

    # Defines a list of attributes to include in +@attributes+ during
    # initialization.  Any attributes not predefined here will raise an error.
    def self.define_attributes(*attrs)
      define_method(:attribute_names) { attrs.map(&:to_s) }
    end

    def initialize(attributes = {})
      @attributes = Hash[(attribute_names||{}).map {|n| [n,nil]}]
      self.attributes = attributes
    end

    def attributes
      @attributes.dup
    end

    def attributes=(attributes)
      attributes.each {|name, value| send("#{name}=", value) }
    end

    # Is overridden in ActiveRecord::Base to copy attributes across during +dup+
    def initialize_dup(other)
      @attributes = other.attributes.dup
      @changed_attributes = other.changed_attributes.dup
      super
    end


    private

    def attribute(name)
      @attributes[name]
    end

    # Based off definitions in ActiveRecord::AttributeMethods::Write
    # and ActiveRecord::AttributeMethods::Dirty
    def attribute=(name, value)
      if changed_attributes[name] == value
        # reverting to original value
        changed_attributes.delete(name)
      elsif @attributes[name] != value
        send("#{name}_will_change!")
      end

      @attributes[name] = value
    end
  end
end
