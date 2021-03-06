#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013,2014,2015 Genome Research Ltd.
class Well < Aliquot::Receptacle
  include Api::WellIO::Extensions
  include ModelExtensions::Well
  include Cherrypick::VolumeByNanoGrams
  include Cherrypick::VolumeByNanoGramsPerMicroLitre
  include Cherrypick::VolumeByMicroLitre
  include StudyReport::WellDetails
  include Tag::Associations
  include AssetRack::WellAssociations::AssetRackAssociation
  include Api::Messages::FluidigmPlateIO::WellExtensions

  class Link < ActiveRecord::Base
    set_table_name('well_links')
    set_inheritance_column(nil)
    belongs_to :target_well, :class_name => 'Well'
    belongs_to :source_well, :class_name => 'Well'
  end
  has_many :stock_well_links,  :class_name => 'Well::Link', :foreign_key => :target_well_id, :conditions => { :type => 'stock' }

  has_many :stock_wells, :through => :stock_well_links, :source => :source_well do
    def attach!(wells)
      attach(wells).tap do |_|
        proxy_owner.save!
      end
    end
    def attach(wells)
      proxy_owner.stock_well_links.build(wells.map { |well| { :type => 'stock', :source_well => well } })
    end
  end

  def is_in_fluidigm?
    sta_plate_purpose_name = "#{configatron.sta_plate_purpose_name}"
    !self.target_wells.detect{|w| w.events.detect {|e| e.family == PlatesHelper::event_family_for_pick(sta_plate_purpose_name)}.nil?}
  end

  named_scope :include_stock_wells, { :include => { :stock_wells => [:requests_as_source,:map] } }
  named_scope :include_map,         { :include => :map }

  named_scope :located_at, lambda { |plate, location|
    { :joins => :map, :conditions => { :maps => { :description => location, :asset_size => plate.size } } }
  }

  has_many :target_well_links, :class_name => 'Well::Link', :foreign_key => :source_well_id, :conditions => { :type => 'stock' }
  has_many :target_wells, :through => :target_well_links, :source => :target_well
  named_scope :stock_wells_for, lambda { |wells| {
    :joins      => :target_well_links,
    :conditions => {
      :well_links =>{
        :target_well_id => [wells].flatten.map(&:id)
        }
      }
    }}



  named_scope :located_at_position, lambda { |position| { :joins => :map, :readonly => false, :conditions => { :maps => { :description => position } } } }

  contained_by :plate

  # We don't handle this in contained by as identifiable pieces of labware
  # may still be contained. (Such as if we implement tube racks)
  def labware
    plate
  end

  delegate :location, :location_id, :location_id=, :to => :container , :allow_nil => true
  @@per_page = 500

  has_one :well_attribute, :inverse_of => :well
  before_create { |w| w.create_well_attribute unless w.well_attribute.present? }

  named_scope :pooled_as_target_by, lambda { |type|
    {
      :joins      => 'LEFT JOIN requests patb ON assets.id=patb.target_asset_id',
      :conditions => [ '(patb.sti_type IS NULL OR patb.sti_type IN (?))', [ type, *Class.subclasses_of(type) ].map(&:name) ],
      :select     => 'assets.*, patb.submission_id AS pool_id'
    }
  }
  named_scope :pooled_as_source_by, lambda { |type|
    {
      :joins      => 'LEFT JOIN requests pasb ON assets.id=pasb.asset_id',
      :conditions => [ '(pasb.sti_type IS NULL OR pasb.sti_type IN (?)) AND pasb.state IN (?)', [ type, *Class.subclasses_of(type) ].map(&:name), Request::Statemachine::OPENED_STATE ],
      :select     => 'assets.*, pasb.submission_id AS pool_id'
    }
  }
  named_scope :in_column_major_order, { :joins => :map, :order => 'column_order ASC' }
  named_scope :in_row_major_order, { :joins => :map, :order => 'row_order ASC' }
  named_scope :in_inverse_column_major_order, { :joins => :map, :order => 'column_order DESC' }
  named_scope :in_inverse_row_major_order, { :joins => :map, :order => 'row_order DESC' }

  named_scope :in_plate_column, lambda {|col,size| {:joins => :map, :conditions => {:maps => {:description => Map::Coordinate.descriptions_for_column(col,size), :asset_size => size }}}}
  named_scope :in_plate_row,    lambda {|row,size| {:joins => :map, :conditions => {:maps => {:description => Map::Coordinate.descriptions_for_row(row,size), :asset_size =>size }}}}

  named_scope :with_blank_samples, {
    :joins => [
      "INNER JOIN aliquots ON aliquots.receptacle_id=assets.id",
      "INNER JOIN samples ON aliquots.sample_id=samples.id"
    ],
    :conditions => ['samples.empty_supplier_sample_name=?',true]
  }

  named_scope :with_contents, {
    :joins => 'INNER JOIN aliquots ON aliquots.receptacle_id=assets.id'
  }

  class << self
    def delegate_to_well_attribute(attribute, options = {})
      class_eval <<-END_OF_METHOD_DEFINITION
        def get_#{attribute}
          self.well_attribute.#{attribute} || #{options[:default].inspect}
        end
      END_OF_METHOD_DEFINITION
    end

    def writer_for_well_attribute_as_float(attribute)
      class_eval <<-END_OF_METHOD_DEFINITION
        def set_#{attribute}(value)
          self.well_attribute.update_attributes!(:#{attribute} => value.to_f)
        end
      END_OF_METHOD_DEFINITION
    end
  end

  def generate_name(_)
    # Do nothing
  end

  def external_identifier
    display_name
  end

  #hotfix
  def well_attribute_with_creation
    self.well_attribute_without_creation || self.build_well_attribute
  end
  alias_method_chain(:well_attribute, :creation)

  delegate_to_well_attribute(:pico_pass)
  delegate_to_well_attribute(:sequenom_count)
  delegate_to_well_attribute(:gel_pass)
  delegate_to_well_attribute(:study_id)
  delegate_to_well_attribute(:gender)

  delegate_to_well_attribute(:concentration)
  alias_method(:get_pico_result, :get_concentration)
  writer_for_well_attribute_as_float(:concentration)

  delegate_to_well_attribute(:molarity)
  writer_for_well_attribute_as_float(:molarity)

  delegate_to_well_attribute(:current_volume)
  alias_method(:get_volume, :get_current_volume)
  writer_for_well_attribute_as_float(:current_volume)

  delegate_to_well_attribute(:buffer_volume, :default => 0.0)
  writer_for_well_attribute_as_float(:buffer_volume)

  delegate_to_well_attribute(:requested_volume)
  writer_for_well_attribute_as_float(:requested_volume)

  delegate_to_well_attribute(:picked_volume)
  writer_for_well_attribute_as_float(:picked_volume)

  delegate_to_well_attribute(:gender_markers)

  def update_gender_markers!(gender_markers, resource)
    if self.well_attribute.gender_markers == gender_markers
      gender_marker_event = self.events.find_by_family('update_gender_markers', :order => 'id desc')
      if gender_marker_event.blank?
        self.events.update_gender_markers!(resource)
      elsif resource == 'SNP'  && gender_marker_event.content != resource
        self.events.update_gender_markers!(resource)
      end
    else
      self.events.update_gender_markers!(resource)
    end

    self.well_attribute.update_attributes!(:gender_markers => gender_markers)
  end

  def update_sequenom_count!(sequenom_count, resource)
    unless self.well_attribute.sequenom_count == sequenom_count
      self.events.update_sequenom_count!(resource)
    end
    self.well_attribute.update_attributes!(:sequenom_count => sequenom_count)

  end

  # The sequenom pass value is either the string 'Unknown' or it is the combination of gender marker values.
  def get_sequenom_pass
    markers = self.well_attribute.gender_markers
    markers.is_a?(Array) ? markers.join : markers
  end

  def map_description
    return read_attribute("map_description") if read_attribute("map_description").present?
    return nil if map.nil?
    return nil unless map.description.is_a?(String)

    map.description
  end

  def valid_well_on_plate
    return false unless self.is_a?(Well)
    well_plate = plate
    return false unless well_plate.is_a?(Plate)
    return false if well_plate.barcode.blank?
    return false if map_id.nil?
    return false unless map.description.is_a?(String)

    true
  end

  def create_child_sample_tube
    Tube::Purpose.standard_sample_tube.create!(:map => self.map, :aliquots => aliquots.map(&:clone)).tap do |sample_tube|
      AssetLink.connect(self, sample_tube)
    end
  end

  def qc_data
    {:pico          => self.get_pico_pass,
     :gel           => self.get_gel_pass,
     :sequenom      => self.get_sequenom_pass,
     :concentration => self.get_concentration }
  end

  def buffer_required?
    get_buffer_volume > 0.0
  end
  private :buffer_required?

  def find_child_plate
    self.children.reverse_each do |child_asset|
      return child_asset if child_asset.is_a?(Well)
    end
    nil
  end

  validate(:on => :save) do |record|
    record.errors.add(:name, "cannot be specified for a well") unless record.name.blank?
  end

  def display_name
    plate_name = self.plate.present? ? self.plate.sanger_human_barcode : '(not on a plate)'
    plate_name ||= plate.display_name # In the even the plate is barcodeless (ie strip tubes) use its name
    "#{plate_name}:#{map ? map.description : ''}"
  end

  def details
    return 'Not yet picked' if plate.nil?
    plate.purpose.try(:name)||'Unknown plate purpose'
  end

  def can_be_created?
    plate.stock_plate?
  end
end
