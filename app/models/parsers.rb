#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module Parsers

  def self.parser_for(filename, content_type, content)
    return nil unless filename.ends_with?('.csv') || content_type == 'text/csv'
    # While FasterCSV tries to detect line endings, it isn't so great with some excel
    # exported CSVs, where a mix of \n and \r\n are used in the same document
    # This converts everything to \n before processing
    cleaned_content = content.gsub(/\r\n?/,"\n")
    csv = FasterCSV.parse(cleaned_content)
    return Parsers::BioanalysisCsvParser.new(csv) if Parsers::BioanalysisCsvParser.is_bioanalyzer?(csv)
    return Parsers::ISCXTenParser.new(csv) if Parsers::ISCXTenParser.is_isc_xten_file?(csv)
    nil
  end

end
