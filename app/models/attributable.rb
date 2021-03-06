#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014 Genome Research Ltd.
# This module can be included into ActiveRecord::Base classes to get the ability to specify the attributes
# that are present.  You can think of this as metadata being stored about the column in the table: it's
# default value, whether it's required, if it has a set of values that are acceptable, or if it's numeric.
# Use the class method 'attribute' to define your attribute:
#
#   attribute(:foo, :required => true)
#   attribute(:bar, :default => 'Something', :in => [ 'Something', 'Other thing' ])
#   attribute(:numeric, :integer => true)
#   attribute(:dependent, :required => true, :if => lambda { |r| r.foo == 'Yep' })
#
# Attribute information can be retrieved from the class through 'attributes', and each one of the attributes
# you define can be converted to a FieldInfo instance using 'to_field_info'.
module Attributable
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      # NOTE: Do not use 'attributes' because that's an ActiveRecord internal name
      class_inheritable_reader :attribute_details
      write_inheritable_attribute(:attribute_details, [])
      class_inheritable_reader :association_details
      write_inheritable_attribute(:association_details, [])
    end
  end

  def attribute_details_for(*args)
    self.class.attribute_details_for(*args)
  end

  def instance_defaults
    self.class.attribute_details.inject({}) do |hash, attribute|
      hash.tap { hash[ attribute.name ] = attribute.default_from(self) if attribute.validator? }
    end
  end

  def attribute_value_pairs
    self.class.attribute_details.inject({}) do |hash, attribute|
      hash.tap { hash[attribute] = attribute.from(self) }
    end
  end

  def association_value_pairs
     self.class.association_details.inject({}) do |hash, attribute|
       hash.tap { hash[attribute] = attribute.from(self) }
     end
   end

  def field_infos
    self.class.attribute_details.map do |detail|
      detail.to_field_info(nil,self)
    end
  end

  def required?(field)
    attribute   = self.class.attribute_details.detect { |attribute| attribute.name == field }
    attribute ||= self.class.association_details.detect { |association| :"#{association.name}_id" == field }
    attribute.try(:required?)
  end

  module ClassMethods
    def attribute(name, options = {}, override_previous = false)
      attribute = Attribute.new(self, name, options)
      attribute.configure(self)

      if override_previous
        attribute_details.delete_if { |a| a.name == name }
        attribute_details.push(attribute)
      elsif attribute_details.detect { |a| a.name == name }.nil?
        attribute_details.push(attribute)
      end
    end

    def association(name, instance_method, options = {})
      association = Association.new(self, name, instance_method, options)
      association.configure(self)
      association_details.push(association)
    end

    def defaults
      attribute_details.inject({}) do |hash, attribute|
        hash.tap { hash[ attribute.name ] = attribute.default }
      end
    end

    def attribute_names
      attribute_details.map(&:name)
    end

    def attribute_details_for(attribute_name)
      attribute_details.detect { |d| d.name.to_sym == attribute_name.to_sym } or raise StandardError, "Unknown attribute #{attribute_name}"
    end
  end

  class Association
    module Target
      def self.extended(base)
        base.class_eval do
          include InstanceMethods
        end
      end

      def for_select_association
        all(:order => 'name ASC').map(&:for_select_dropdown).compact
      end

      def default
        nil
      end

      module InstanceMethods
        def for_select_dropdown
          [ self.name, self.id ]
        end
      end
    end

    attr_reader :name

    def initialize(owner, name, method, options = {})
      @owner, @name, @method = owner, name, method
      @required = !!options.delete(:required) || false
      @scope = Array(options.delete(:scope))
    end

    def required?
      @required
    end

    def optional?
      not self.required?
    end

    def assignable_attribute_name
      :"#{@name}_#{@method}"
    end

    def from(record)
      record.send(@name).send(@method)
    end

    def display_name
      Attribute::find_display_name(@owner,  name)
    end

    def kind
      FieldInfo::SELECTION
    end

    def find_default(*args)
      nil
    end

    def selection?
      true
    end

    def selection_options(_)
      get_scoped_selection.all.map(&@method.to_sym).sort
    end

    def to_field_info(*args)
      FieldInfo.new(
        :display_name  => display_name,
        :key           => assignable_attribute_name,
        :kind          => kind,
        :selection     => selection_options(nil)
      )
    end

    def get_scoped_selection
      @scope.inject(@owner.reflections[@name.to_sym].klass){|k,v| k.send(v.to_sym) }
    end
    private :get_scoped_selection

    def configure(target)
      target.class_eval(%Q{
        def #{assignable_attribute_name}=(value)
          record = self.class.reflections[:#{@name}].klass.find_by_#{@method}(value) or
            raise ActiveRecord::RecordNotFound, "Could not find #{@name} with #{@method} \#{value.inspect}"
          send(:#{@name}=, record)
        end

        def #{assignable_attribute_name}
          send(:#{@name}).send(:#{@method})
        end
      })
    end
  end

  class Attribute
    attr_reader :name
    attr_reader :default

    alias_method :assignable_attribute_name, :name

    def initialize(owner, name, options = {})
      @owner, @name, @options = owner, name.to_sym, options
      @default  = options.delete(:default)
      @required = !!options.delete(:required) || false
    end

    def from(record)
      record[self.name]
    end

    def default_from(origin=nil)
      return nil if origin.nil?
      return origin.validator_for(name).default if validator?
    end

    def validator?
      @options.key?(:validator)
    end

    def required?
      @required
    end

    def optional?
      not self.required?
    end

    def numeric?
      @options.key?(:integer)
    end

    def float?
      @options.key?(:positive_float)
    end

    def boolean?
      @options.key?(:boolean)
    end

    def fixed_selection?
      @options.key?(:in)
    end

    def selection?
      fixed_selection?||@options.key?(:selection)
    end

    def method?
      @options.key?(:with_method)
    end

    def validate_method
      @options[:with_method]
    end

    def selection_values
      @options[:in]
    end

    def valid_format
      @options[:with]
    end

    def valid_format?
      valid_format
    end

    def configure(model)
      conditions = @options.slice(:if)
      save_blank_value = @options.delete(:save_blank)
      allow_blank = save_blank_value

      model.with_options(conditions) do |object|
        # false.blank? == true, so we exclude booleans here, they handle themselves further down.
        object.validates_presence_of(name) if self.required? && ! self.boolean?
        object.with_options(:allow_nil => self.optional?, :allow_blank => allow_blank) do |required|
          required.validates_inclusion_of(name, :in => [true, false]) if self.boolean?
          required.validates_numericality_of(name, :only_integer => true) if self.numeric?
          required.validates_numericality_of(name, :greater_than => 0) if self.float?
          required.validates_inclusion_of(name, :in => self.selection_values, :allow_false => true) if self.fixed_selection?
          required.validates_format_of(name, :with => self.valid_format) if self.valid_format?
          required.validate do |record|
            valid = record.validator_for(name).valid_options.to_a.include?(record.send(name))
            record.errors.add(name,"is not in the list") unless valid
            valid
          end if self.validator?
          required.validate(self.validate_method) if self.method?
        end
      end

      unless save_blank_value
        model.before_validation do |record|
          value = record.send(name)
          record.send("#{name}=", nil) if value and value.blank?
        end
      end

      unless (condition = conditions[:if]).nil?
        model.before_validation do |record|
          record[name] = nil unless record.send(condition)
        end
      end
    end

    def self.find_display_name(klass, name)
      translation = I18n.t("metadata.#{ klass.name.underscore.gsub('/', '.') }.#{ name }")
      if translation.is_a?(Hash) # translation found, we return the label
        return translation[:label]
      else
        superclass = klass.superclass
        if superclass != ActiveRecord::Base # a subclass , try the superclass name scope
          return find_display_name(superclass, name)
        else # translation not found
          return translation # shoulb be an error message, so that's ok
        end
      end
    end

    def display_name
      Attribute::find_display_name(@owner,  name)
    end

    def find_default(object = nil, metadata = nil)
      default_from(metadata) || object.try(self.name) || self.default
    end

    def kind
      return FieldInfo::SELECTION if self.selection?
      return FieldInfo::BOOLEAN if self.boolean?
      FieldInfo::TEXT
    end

    def selection_from_metadata(metadata)
      return nil unless metadata.present?
      return metadata.validator_for(name).valid_options.to_a if validator?
    end

    def selection_options(metadata)
      self.selection_values||selection_from_metadata(metadata)||[]
    end

    def to_field_info(object = nil, metadata = nil)
      options = {
        # TODO[xxx]: currently only working for metadata, the only place attributes are used
        :display_name  => display_name,
        :key           => assignable_attribute_name,
        :default_value => find_default(object,metadata),
        :kind          => kind
      }
      options.update(:selection => selection_options(metadata)) if self.selection?
      FieldInfo.new(options)
    end
  end
end
