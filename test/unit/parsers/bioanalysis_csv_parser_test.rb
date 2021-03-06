#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require File.dirname(__FILE__) + '/../../test_helper'

class BioanalysisCsvParserTest < ActiveSupport::TestCase

  def read_file(filename)
      fd = File.open(filename, "r")
      content = []
      while (line = fd.gets)
        content.push line
      end
      fd.close
      Iconv.conv('utf-8', 'WINDOWS-1253',content.join(""))
  end

  context "Parser" do
    context "With a valid csv file" do
      setup do
        @filename = File.dirname(__FILE__)+"/../../data/bioanalysis_qc_results.csv"
        @content = read_file @filename
        @csv = FasterCSV.parse(@content)
      end

      should "return a BioanalysisCsvParser" do
        Parsers::BioanalysisCsvParser.expects(:new).with(@csv).returns(:pass)
        assert_equal :pass, Parsers.parser_for(@filename,nil,@content)
      end
    end

    context "With an unreleated csv file" do
      setup do
        @filename = File.dirname(__FILE__)+"/../../data/fluidigm.csv"
        @content = read_file @filename
      end

      should "return a BioanalysisCsvParser" do
        assert_equal nil, Parsers.parser_for(@filename,nil,@content)
      end
    end

    context "with a non csv file" do
      setup do
        @filename = File.dirname(__FILE__)+"/../../data/example_file.txt"
        @content = read_file @filename
      end

      should "return a BioanalysisCsvParser" do
        assert_equal nil, Parsers.parser_for(@filename,nil,@content)
      end
    end
  end

  context "A Bioanalysis parser of CSV" do
    context "with a valid CSV biorobot file" do
      setup do
        filename = File.dirname(__FILE__)+"/../../data/bioanalysis_qc_results.csv"
        content = read_file filename

        @parser = Parsers::BioanalysisCsvParser.new(FasterCSV.parse(content))
      end

      should "parse last sample of testing file correctly" do
        assert_equal "1", @parser.parse_overall([157,158])
      end

      should "use get_groups method to find matching regexp" do
        test_data = [[24, 25], [37, 38], [49, 50], [61, 62], [73, 74], [85, 86],
        [97, 98], [109, 110], [121, 122], [133, 134], [145, 146], [157,158]]
        assert_equal test_data, @parser.get_groups(/Overall.*/m)
      end



      should "parses a CSV example file" do
        assert_equal "25.65", @parser.concentration("A1")
        assert_equal "72.5",  @parser.molarity("A1")
        assert_equal "18.06", @parser.concentration("B1")
        assert_equal "50.5",  @parser.molarity("B1")
      end

      should "map by well" do
        results = [
          ["A1","25.65","72.5"],
          ["B1","18.06","50.5"],
          ["C1","27.44","80.2"],
          ["D1","26.69","77.6"],
          ["E1","27.06","79.8"],
          ["F1","17.60","50.2"],
          ["G1","27.24","78.2"],
          ["H1","15.67","43.9"],
          ["A2","22.59","66.4"],
          ["B2","26.26","77.2"],
          ["C2","10.65","30.0"],
          ["D2","25.38","73.2"]
        ]
        @parser.each_well_and_parameters do |*args|
          assert results.delete(args).present?, "#{args.inspect} was an unexpected result"
        end
        assert results.empty?, "Some expected results were not returned: #{results.inspect}"
      end
    end
    context "with an invalid CSV biorobot file" do
      setup do
        filename = File.dirname(__FILE__)+"/../../data/bioanalysis_qc_results-with-error.csv"
        content = read_file filename

        @parser = Parsers::BioanalysisCsvParser.new(FasterCSV.parse(content))
      end

      should "raise an exception while accessing any information" do
        assert_raises(Parsers::BioanalysisCsvParser::InvalidFile) { @parser.concentration("A1") }
      end
    end
  end
end
