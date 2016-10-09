require "test_helper"

class LibPoolNormTubeGeneratorTest < ActiveSupport::TestCase

  attr_reader :plate, :user, :study

  def valid_plate
    plate = create(:plate_with_wells)
    plate.plate_purpose.stubs(:name).returns("Lib PCR-XP")
    plate.stubs(:state).returns("qc_complete")
    plate
  end

  def setup
    @plate = valid_plate
    @user = create(:admin)
    @study = create(:study)
  end

  def mock_transfer(generator)
    transfer = mock("transfer")
    transfer.stubs(:destination).returns(create(:lib_pcr_xp_tube))
    generator.transfer_template.stubs(:create!).returns(transfer)
  end

  test "should not be valid without a valid plate barcode" do
    refute LibPoolNormTubeGenerator.new("dodgy barcode", user, study).valid?
  end

  test "should not be valid without a user" do
    plate = valid_plate
    Plate.stubs(:find_from_machine_barcode).returns(plate)
    refute LibPoolNormTubeGenerator.new(plate.ean13_barcode, nil, study).valid?
  end

  test "should not be valid without a study" do
    plate = valid_plate
    Plate.stubs(:find_from_machine_barcode).returns(plate)
    refute LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, nil).valid?
  end

  test "should not be valid unless the state of the plate is qc complete" do
    plate = create(:lib_pcr_xp_plate)
    refute LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, study).valid?
  end

  test "should not be valid unless the plate is a Lib PCR-XP plate" do
    plate = create(:plate)
    plate.stubs(:state).returns("qc_complete")
    Plate.stubs(:find_from_machine_barcode).returns(plate)
    refute LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, study).valid?
  end

  context "with a valid plate" do

    attr_reader :plate, :transfer_template, :generator

    setup do
      @plate = valid_plate
      Plate.stubs(:find_from_machine_barcode).returns(plate)
      @generator =  LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, study)
    end

    should "be valid" do
      assert generator.valid?
    end

    should "lib pool tubes should have the correct number" do
      refute generator.lib_pool_tubes.empty?
      assert_equal generator.plate.wells.length, generator.lib_pool_tubes.length
    end

    should "have a transfer template" do
      assert generator.transfer_template.present?
    end

    should "create all of the destination tubes with a state of qc complete" do
      mock_transfer(generator)
      generator.create!
      refute generator.destination_tubes.empty?
      assert_equal generator.destination_tubes.length, generator.lib_pool_tubes.length
      assert generator.destination_tubes.all? { |dt| dt.state == "qc_complete" }
    end

    should "create an asset group which includes all of the destination tubes" do
      mock_transfer(generator)
      generator.create!
      assert generator.asset_group.present?
      assert_equal generator.destination_tubes.length, generator.asset_group.assets.length
    end

    should "put all of the destination tubes in the Cluster formation freezer" do
      mock_transfer(generator)
      generator.create!
      assert generator.destination_tubes.all? { |dt| dt.location.name == "Cluster formation freezer" }
    end
  end

end
