# A {Task} used in {CherrypickPipeline cherrypick pipelines}
# Performs the main bulk of cherrypick action. Although a lot of the options
# on this page are presented as part of the previous step, and get persisted on this
# page as hidden fields.
# This page shows a drag-drop plate layout which lets users set-up the way the plate will be picked.
# The target asset of each request will have its plate and map set accordingly.
# Well attributes are set to track picking volumes
#
# @see PlateTemplateTask for previous step
# @see Tasks::CherrypickHandler for behaviour included in the {WorkflowsController}
class CherrypickTask < Task
  EMPTY_WELL          = [0, 'Empty', ''].freeze
  TEMPLATE_EMPTY_WELL = [0, '---', ''].freeze

  # An instance of this class represents the target plate being picked onto.  It can have a template
  # and be a partial plate, and so when wells are picked into it we need to ensure that we don't hit
  # the template/partial wells.
  class PickTarget
    def self.for(plate_purpose)
      cherrypick_direction = plate_purpose.nil? ? 'column' : plate_purpose.cherrypick_direction
      const_get("by_#{cherrypick_direction}".classify)
    end

    def initialize(template, asset_shape = nil, partial = nil)
      @wells = []
      @size = template.size
      @shape = asset_shape || AssetShape.default
      initialize_already_occupied_wells_from(template, partial)
      add_any_wells_from_template_or_partial(@wells)
    end

    # Deals with generating the pick plate by travelling in a row direction, so A1, A2, A3 ...
    class ByRow < PickTarget
      def well_position(wells)
        (wells.size + 1) > @size ? nil : wells.size + 1
      end
      private :well_position

      # rubocop:todo Style/MultilineBlockChain
      def completed_view
        @wells.dup.tap do |wells|
          complete(wells)
        end.each_with_index.inject([]) do |wells, (well, index)|
          wells.tap { wells[@shape.horizontal_to_vertical(index + 1, @size)] = well }
        end.compact
      end
      # rubocop:enable Style/MultilineBlockChain
    end

    # Deals with generating the pick plate by travelling in a column direction, so A1, B1, C1 ...
    class ByColumn < PickTarget
      def well_position(wells)
        @shape.vertical_to_horizontal(wells.size + 1, @size)
      end
      private :well_position

      def completed_view
        @wells.dup.tap { |wells| complete(wells) }
      end
    end

    # Deals with generating the pick plate by travelling in an interlaced column direction, so A1, C1, E1 ...
    class ByInterlacedColumn < PickTarget
      def well_position(wells)
        @shape.interlaced_vertical_to_horizontal(wells.size + 1, @size)
      end
      private :well_position

      # rubocop:todo Style/MultilineBlockChain
      def completed_view
        @wells.dup.tap do |wells|
          complete(wells)
        end.each_with_index.inject([]) do |wells, (well, index)|
          wells.tap { wells[@shape.vertical_to_interlaced_vertical(index + 1, @size)] = well }
        end.compact
      end
      # rubocop:enable Style/MultilineBlockChain
    end

    def empty?
      @wells.empty?
    end

    def content
      @wells
    end

    attr_reader :size

    def full?
      @wells.size == @size
    end

    def push(request_id, plate_barcode, well_location)
      @wells << [request_id, plate_barcode, well_location]
      add_any_wells_from_template_or_partial(@wells)
      self
    end

    # Completes the given well array such that it looks like the plate has been completely picked.
    def complete(wells)
      until wells.size >= @size
        add_empty_well(wells)
        add_any_wells_from_template_or_partial(wells)
      end
    end
    private :complete

    # Determines the wells that are already occupied on the template or the partial plate.  This is
    # then used in add_any_wells_from_template_or_partial to fill them in as wells are added by the
    # pick.
    def initialize_already_occupied_wells_from(template, partial)
      @used_wells = {}.tap do |wells|
        [partial, template].compact.each do |plate|
          plate.wells.each { |w| wells[w.map.horizontal_plate_position] = w.map.description }
        end
      end
    end
    private :initialize_already_occupied_wells_from

    # Every time a well is added to the pick we need to make sure that the template and partial are
    # checked to see if subsequent wells are already taken.  In other words, after calling this method
    # the next position on the pick plate is known to be empty.
    def add_any_wells_from_template_or_partial(wells)
      wells << CherrypickTask::TEMPLATE_EMPTY_WELL until (wells.size >= @size) || @used_wells[well_position(wells)].nil?
    end
    private :add_any_wells_from_template_or_partial

    def add_empty_well(wells)
      wells << CherrypickTask::EMPTY_WELL
    end
    private :add_empty_well
  end

  #
  # Returns a list with the destination positions for the control wells distributed by
  # using batch_id and num_plate as position generators.
  def control_positions(batch_id, num_plate, num_free_wells, num_control_wells)
    unique_number = batch_id

    # Generation of the choice
    positions = []
    available_positions = (0...num_free_wells).to_a

    while positions.length < num_control_wells
      current_size = available_positions.length
      position = available_positions.slice!(unique_number % current_size)
      position_for_plate = (position + num_plate) % num_free_wells
      positions.push(position_for_plate)
      unique_number /= current_size
    end

    positions
  end

  def pick_new_plate(requests, template, robot, plate_purpose, control_plate = nil)
    target_type = PickTarget.for(plate_purpose)
    perform_pick(requests, robot, control_plate) do
      target_type.new(template, plate_purpose.try(:asset_shape))
    end
  end

  def pick_onto_partial_plate(requests, template, robot, partial_plate, control_plate = nil)
    purpose = partial_plate.plate_purpose
    target_type = PickTarget.for(purpose)

    perform_pick(requests, robot, control_plate) do
      target_type.new(template, purpose.try(:asset_shape), partial_plate).tap do
        partial_plate = nil # Ensure that subsequent calls have no partial plate
      end
    end
  end

  # Creates control requests for the control assets provided and adds them to the batch
  def create_control_requests!(batch, control_assets)
    order = batch.requests.first.submission.orders.first
    destination_control_wells = nil
    order.create_requests_for_assets!(control_assets, nil, true) do |created_wells|
      destination_control_wells = created_wells
    end
    requests_from_controls = destination_control_wells.map(&:requests_as_target).flatten
    batch.requests << requests_from_controls

    requests_from_controls
  end

  # Adds any consecutive list of control requests into the current_destination_plate
  def add_any_consecutive_control_requests(control_positions, batch, control_assets, current_destination_plate)
    while (asset_position = control_positions.find_index(current_destination_plate.content.length))
      control_asset = control_assets[asset_position]
      add_control_request(batch, control_asset, current_destination_plate)
    end
  end

  # Creates a new control request for the control_asset and adds it into the current_destination_plate plate
  def add_control_request(batch, control_asset, current_destination_plate)
    control_request = create_control_requests!(batch, [control_asset]).first
    control_request.start!
    current_destination_plate.push(control_request.id,
                                   control_request.asset.plate.human_barcode, control_request.asset.map_description)
  end

  # Adds any remaining control requests not already added, into the current_destination_plate plate
  def add_remaining_control_requests(control_positions, batch, control_assets, current_destination_plate)
    control_positions.each_with_index do |pos, idx|
      if pos >= current_destination_plate.content.length
        control_asset = control_assets[idx]
        add_control_request(batch, control_asset, current_destination_plate)
      end
    end
  end

  def perform_pick(requests, robot, control_plate)
    max_plates = robot.max_beds
    raise StandardError, 'The chosen robot has no beds!' if max_plates.zero?

    destination_plates = []
    current_destination_plate = yield # instance of ByRow, ByColumn or ByInterlacedColumn
    source_plates = Set.new
    plates_hash = build_plate_wells_from_requests(requests) # array formed from requests

    # Initial settings needed for control requests addition
    if control_plate
      num_plate = 0
      batch = requests.first.batch
      control_assets = control_plate.wells.joins(:samples)
      control_positions = control_positions(batch.id, num_plate, current_destination_plate.size, control_assets.count)
    end

    push_completed_plate = lambda do
      destination_plates << current_destination_plate.completed_view
      current_destination_plate = yield # reset to start picking to a fresh one
      if control_plate
        # when we start a new plate we rebuild the list of positions where the requests should be placed
        num_plate += 1
        control_positions = control_positions(batch.id, num_plate, current_destination_plate.size, control_assets.count)
      end
    end

    plates_hash.each do |request_id, plate_barcode, well_location|
      source_plates << plate_barcode
      if control_plate
        # If we are adding control wells we will add everything that is together in this line (column or row)
        # before passing control to add normal wells
        add_any_consecutive_control_requests(control_positions, batch, control_assets, current_destination_plate)
        push_completed_plate.call if current_destination_plate.full?
      end
      # Add this well to the pick and if the plate is filled up by that push it to the list.
      current_destination_plate.push(request_id, plate_barcode, well_location)
      push_completed_plate.call if current_destination_plate.full?
    end

    # If there are any remaining control requests, we'll add all of them at the end of the last plate
    add_remaining_control_requests(control_positions, batch, control_assets, current_destination_plate) if control_plate

    # Ensure that a non-empty plate is stored
    push_completed_plate.call unless current_destination_plate.empty?

    [destination_plates, source_plates]
  end
  private :perform_pick

  def partial
    'cherrypick_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_cherrypick_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_cherrypick_task(self, params)
  rescue Cherrypick::Error => e
    workflow.send(:flash)[:error] = e.message
    false
  end

  private

  # returns array [ [ request id, source plate barcode, source coordinate ] ]
  def build_plate_wells_from_requests(requests)
    loaded_requests = Request.where(requests: { id: requests })
                             .includes(asset: [{ plate: :barcodes }, :map])
    sorted_requests = loaded_requests.sort_by do |request|
      [request.asset.plate.id, request.asset.map.column_order]
    end
    sorted_requests.map do |request|
      [request.id, request.asset.plate.human_barcode, request.asset.map_description]
    end
  end
end
