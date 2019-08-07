# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # The library type is a value which must already exist.
    # Weirdly the library type is stored as a value rather than an association.
    class LibraryType
      include Base
      include ValueRequired

      validate :check_library_type_exists

      def update(attributes = {})
        return unless valid? && attributes[:aliquot].present?

        aliquots.each do |aliquot|
          aliquot.library_type = value
        end
      end

      private

      def check_library_type_exists
        return if ::LibraryType.find_by(name: value).present?

        errors.add(:base, "could not find #{value} library type.")
      end
    end
  end
end
