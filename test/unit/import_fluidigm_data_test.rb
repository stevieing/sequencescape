#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2015 Genome Research Ltd.
require "test_helper"

class ImportFluidigmDataTest < ActiveSupport::TestCase
  context "With a fluidigm file" do

    def create_fluidigm_file
      @XY = 'M'
      @XX = 'F'
      @YY = 'F'
      @NC = 'Unknown'

      @file = File.open("#{RAILS_ROOT}/test/data/fluidigm.csv")
      @fluidigm = FluidigmFile.new(@file.read)
      @well_maps = {
        'S06' => {
          :markers => [ @XY,@XY,@XY ],
          :count   => 94
        },
        'S04' => {
          :markers=> [ @NC, @XX, @XX ],
          :count=>   92
        },
        'S43' => {
          :markers=> [ @XX, @XX, @XX ],
          :count=>   94
        }
      }
      @fluidigm
    end

    def create_stock_plate(barcode)
      plate_source = Factory :plate, {
        :name => "Stock plate #{barcode}",
        :size => 192,
        :purpose=>Purpose.find_by_name('Stock Plate'),
        :barcode => barcode
      }
      @sample = Factory :sample, :name=>"abc"
            well_source = Well.create!.tap { |well| well.aliquots.create!(:sample => @sample) }
      plate_source.add_and_save_well(well_source)
      plate_source
    end

    def create_plate_with_fluidigm(barcode, fluidigm_barcode, stock_plate)
      plate_target = Factory :plate, {
        :name => "Cherrypicked #{barcode}",
        :size => 192,
        :barcode => barcode,
        :plate_metadata_attributes=>{
          :fluidigm_barcode => fluidigm_barcode
        }
      }

      well_target = Well.new
      plate_target.add_and_save_well(well_target)

      RequestType.find_by_key("pick_to_fluidigm").create!({
        :state => 'passed',
        :asset => stock_plate.wells.first,
        :target_asset => well_target,
        :request_metadata_attributes => {
            :target_purpose_id => PlatePurpose.find_by_name("Fluidigm 192-24").id
          }
        })
      plate_target
    end
    setup do
      @fluidigm_file = create_fluidigm_file
      @stock_plate = create_stock_plate("87654321")
      @plate1 = create_plate_with_fluidigm("12345671", '1381832088', @stock_plate)
      @plate2 = create_plate_with_fluidigm( "12345672", "1234567891", @stock_plate)
    end
    context "before uploading the fluidigm file to a corresponding plate" do
      should "we get this plate inside the requiring_fluidigm_data scope" do
        @plates_requiring_fluidigm = Plate.requiring_fluidigm_data
        assert_equal true, @plates_requiring_fluidigm.include?(@plate1)
        assert_equal true, @plates_requiring_fluidigm.include?(@plate2)
      end
    end
    context "after uploading the fluidigm file" do
      setup do
        @plate1.apply_fluidigm_data(@fluidigm_file)
      end

      should "we only get the plates that haven't been updated yet" do
        @plates_requiring_fluidigm = Plate.requiring_fluidigm_data
        assert_equal false, @plates_requiring_fluidigm.include?(@plate1)
        assert_equal true, @plates_requiring_fluidigm.include?(@plate2)
      end
    end
  end
end
