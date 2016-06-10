require_relative '../../test_helper'

class ColumnListTest < ActiveSupport::TestCase

  attr_reader :column_list, :column_headings, :yaml, :valid_columns, :ranges, :styles, :worksheet

  def setup
    @yaml = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns.yml"))).with_indifferent_access
    conditional_formattings = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","conditional_formatting.yml"))).with_indifferent_access
    @column_list = SampleManifestExcel::ColumnList.new(yaml, conditional_formattings)
    @valid_columns = yaml.collect { |k,v| k if v.present? }.compact
    @ranges = build(:range_list, options: YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges.yml"))))
  end

  test "should create a list of columns" do
    assert_equal yaml.length, column_list.count
  end

  test "columns should have conditionsl formattings" do
    assert_equal yaml[:gender][:conditional_formattings].length, column_list.find_by(:gender).conditional_formattings.count
    assert_equal yaml[:sibling][:conditional_formattings].length, column_list.find_by(:sibling).conditional_formattings.count
  end

  test "#headings should return headings" do
    assert_equal yaml.values.compact.collect { |column| column[:heading] }, column_list.headings
  end

  test "#find_by returns correct column" do
    assert column_list.find_by(yaml.keys.first)
  end

  test "each column should have a number" do
    valid_columns.each_with_index do |column, i|
      assert_equal i+1,column_list.find_by(column).number
    end
  end

  test "#extract should return correct list of columns" do
    names = yaml.each_with_index.map { |(k, v), i|  k if i.odd? }.compact
    column_list_new = column_list.extract(names)
    assert_equal names.length, column_list_new.count
    names.each_with_index do |name, i|
      assert column_list_new.find_by(name)
      assert_equal i+1, column_list_new.find_by(name).number
    end
  end

  test "#add adds column to column list" do
    column_list_new = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: "Plate ID")
    column_list_new.add(column)
    assert_equal 1, column_list_new.columns.count
    assert_equal 1, column_list_new.find_by(:plate_id).number
  end

  test "#add_with_dup should add dupped column" do
    column_list_new = SampleManifestExcel::ColumnList.new
    column = SampleManifestExcel::Column.new(name: :plate_id, heading: "Plate ID")
    column_list_new.add_with_dup(column)
    refute_equal column, column_list_new.find_by(:plate_id)
  end

  test "#with_validations should return a list of columns which have validations" do
    assert_equal 2, column_list.with_validations.count
  end

  test "#with_unlocked should return a list of columns which are unlocked" do
    assert_equal 8, column_list.with_unlocked.count
  end

  test "#update should update columns" do
    column_list.update(10, 15, ranges, Axlsx::Workbook.new)
    column_list.each { |k, column| assert column.range }
    column = column_list.find_by(:gender)
    assert_equal ranges.find_by(:gender).absolute_reference, column.validation.options[:formula1]
  end

  test "#add_validation_and_conditional_formatting should add it to axlsx_worksheet" do
    axlsx_worksheet = Axlsx::Worksheet.new(Axlsx::Workbook.new)
    column_list.update(10, 15, ranges, Axlsx::Workbook.new)
    column_list.add_validation_and_conditional_formatting(axlsx_worksheet)

    assert axlsx_worksheet.send(:data_validations).find {|validation| validation.formula1 == column_list.find_by(:gender).validation.options[:formula1]}

    assert_equal column_list.count, axlsx_worksheet.send(:conditional_formattings).count
    column = column_list.find_by(:sibling)
    assert axlsx_worksheet.send(:conditional_formattings).any? {|conditional_formatting| conditional_formatting.sqref == column.reference}
    conditional_formatting = axlsx_worksheet.send(:conditional_formattings).select {|conditional_formatting| conditional_formatting.sqref == column.reference}
    assert_equal column.conditional_formattings.options.count, conditional_formatting.last.rules.count
    assert_equal  ERB::Util.html_escape(column.conditional_formattings.options.last['formula']), conditional_formatting.last.rules.last.formula.first
  end

end