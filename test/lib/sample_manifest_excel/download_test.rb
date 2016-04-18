
require 'test_helper.rb'

class DownloadTest < ActiveSupport::TestCase

  attr_reader :download, :spreadsheet, :sample_manifest, :column_list

  def setup
    @sample_manifest = create(:sample_manifest_with_samples)
    @column_list = SampleManifestExcel::ColumnList.new(YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_columns_basic_plate.yml"))))
    @download = SampleManifestExcel::Download.new(sample_manifest, column_list)
    download.save('test.xlsx')
    @spreadsheet = Roo::Spreadsheet.open('test.xlsx')
  end

  test "should create an excel file"  do
    assert File.file?('test.xlsx')
  end

  test "should create a worksheet" do
    assert_equal "DNA Collections Form", spreadsheet.sheets.first
  end

  test "should add the title to the first worksheet" do
    assert_equal "DNA Collections Form", spreadsheet.sheet(0).cell(1,1)
  end

  test "should add study to the worksheet" do
    assert_equal "Study:", spreadsheet.sheet(0).cell(5,1)
    assert_equal sample_manifest.study.abbreviation, spreadsheet.sheet(0).cell(5,2)
  end

  test "should add supplier to worksheet" do
    assert_equal "Supplier:", spreadsheet.sheet(0).cell(6,1)
    assert_equal sample_manifest.supplier.name, spreadsheet.sheet(0).cell(6,2)
  end

  test "should add standard headings to worksheet" do
    download.columns.headings.each_with_index do |heading, i|
      assert_equal heading, spreadsheet.sheet(0).cell(9,i+1)
    end
  end

  test "should have a type" do
    assert_equal sample_manifest.asset_type, download.type
  end

  test "should add all of the samples" do
    assert_equal sample_manifest.samples.count+9, spreadsheet.sheet(0).last_row
  end

  test "should add the attributes to the column list" do
    assert download.columns.find_by("sanger_plate_id").attribute?
    assert download.columns.find_by("well").attribute?
    assert download.columns.find_by("donor_id").attribute?
  end

  test "should add the attributes for each sample" do
    [sample_manifest.samples.first, sample_manifest.samples.last].each do |sample|
      download.columns.with_attributes.each do |column|
        assert_equal column.attribute_value(sample), spreadsheet.sheet(0).cell(sample_manifest.samples.index(sample)+10, column.number)
      end
    end
  end

  test "should add the data validations" do
    assert_equal column_list.with_validations.count, download.worksheet.send(:data_validations).count
    column = column_list.with_validations.first
    assert_equal column.range, download.worksheet.send(:data_validations).first.sqref
    column = column_list.with_validations.last
    assert_equal column.range, download.worksheet.send(:data_validations).last.sqref
    assert download.worksheet.send(:data_validations).find {|validation| validation.formula1 == column_list.find_by("gender").validation["formula1"]}
  end

  test "should unlock cells when required" do
    download.columns.with_unlocked.each do |column|
      assert_equal download.styles[:unlock].reference, download.worksheet[column.range].first.style
      assert_equal download.styles[:unlock].reference, download.worksheet[column.range].last.style
    end 
  end

  test "worksheet should be protected with password" do
    assert download.password
    assert download.worksheet.sheet_protection.password
  end

  test "panes should be frozen correctly" do
    assert_equal download.freeze_after_column('sanger_sample_id').number, download.worksheet.sheet_view.pane.x_split
    assert_equal download.first_row-1, download.worksheet.sheet_view.pane.y_split
    assert_equal "frozen", download.worksheet.sheet_view.pane.state
  end

  test "should add conditional formatting to unlocked columns" do
    assert_equal column_list.with_unlocked.count, download.worksheet.send(:conditional_formattings).count
    column = column_list.with_unlocked.first
    assert_equal column.range, download.worksheet.send(:conditional_formattings).first.sqref
    column = column_list.with_unlocked.last
    assert_equal column.range, download.worksheet.send(:conditional_formattings).last.sqref
    assert download.worksheet.send(:conditional_formattings).all? {|cf| cf.rules.first.formula.first == 'FALSE'}
  end

  def teardown
    File.delete('test.xlsx') if File.exists?('test.xlsx')
  end
  
end
