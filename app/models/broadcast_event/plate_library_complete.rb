#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class BroadcastEvent::PlateLibraryComplete < BroadcastEvent

  set_event_type 'library_complete'

  # Properties takes :order_id

  seed_class Plate

  has_subject(:order) {|_,e| e.order }
  has_subject(:study) {|_,e| e.order.study }
  has_subject(:project) {|_,e| e.order.project }
  has_subject(:submission) {|_,e| e.order.submission }

  has_subject(:library_source_labware,:library_source_plates)

  has_subjects(:stock_plate,:original_stock_plates)
  has_subjects(:sample) { |plate,e| plate.samples_in_order_by_target(e.properties[:order_id]) }

  def order
    @order ||= Order.find(properties[:order_id],:include=>[:study,:project,:submission])
  end

  has_metadata(:library_type) {|_,e| e.order.request_options['library_type'] }
  has_metadata(:fragment_size_from) {|_,e| e.order.request_options['fragment_size_required_from'] }
  has_metadata(:fragment_size_to) {|_,e| e.order.request_options['fragment_size_required_to'] }
  has_metadata(:bait_library) {|_,e| e.order.request_options[:bait_library_name] }

  has_metadata(:order_type) {|_,e| e.order.order_role.try(:role)||'UNKNOWN' }
  has_metadata(:submission_template) {|_,e| e.order.template_name }

  has_metadata(:team) {|plate,e| plate.team }
end
