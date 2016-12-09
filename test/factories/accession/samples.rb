FactoryGirl.define do

  factory :sample_metadata_for_accessioning, class: Sample::Metadata do
    sample_taxon_id 1
    sample_common_name "A common name"
    donor_id "1"
    gender "Unknown"
    phenotype "Indescribeable"
    growth_condition "No"
    sample_public_name "Sample 666"
    disease_state "Awful"
  end

  factory :sample_for_accessioning_with_open_study, parent: :sample do
    studies           { [ create(:open_study, accession_number: "ENA123") ] }
    sample_metadata   { create(:sample_metadata_for_accessioning) }
  end

  factory :sample_for_accessioning_with_managed_study, parent: :sample do
    studies           { [ create(:managed_study, accession_number: "ENA123") ] }
    sample_metadata   { create(:sample_metadata_for_accessioning) }
  end

  factory :accession_sample, class: Accession::Sample do
    standard_tags { build(:standard_accession_tag_list) }
    sample        { create(:sample_for_accessioning_with_open_study) }

    initialize_with { new(standard_tags, sample) }
  end
end