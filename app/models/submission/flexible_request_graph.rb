#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
module Submission::FlexibleRequestGraph

  class RequestChainError < RuntimeError; end

  class RequestChain

    attr_reader :order, :source_assets, :preplexed, :built, :multiplexed
    alias_method :built?, :built
    alias_method :multiplexed?, :multiplexed
    alias_method :preplexed?, :preplexed

    def initialize(order,source_assets, multiplexing_assets)
      @order = order
      @source_assets = source_assets
      @multiplexing_assets = multiplexing_assets
      @preplexed = multiplexing_assets.present?
      @built = false
      @multiplexed = false
    end

    def build!
      raise RequestChainError, "Request chains can only be built once" if built?
      raise StandardError, 'No request types specified!' if request_types.empty?
      request_types.inject(source_assets) do |source_assets,request_type|
        link = ChainLink.build!(request_type,multiplier_for(request_type),source_assets,self)
        break if preplexed && link.multiplexed?
        link.target_assets
      end
      @built = true
    end

    ##
    # multiplexing_assets returns @multiplexing_assets if present
    # otherwise it yields to any presented block and assumes it returns
    # the multiplexing_assets
    def multiplexing_assets
      @multiplexed = true

      @multiplexing_assets ||= yield if block_given?
      @multiplexing_assets
    end

    private

    def request_types
      order.request_types.map {|request_type_id| RequestType.find(request_type_id) }
    end

    def multiplier_for(request_type)
      multipliers[request_type.id.to_s]
    end

    def multipliers
      @multipliers ||= Hash.new { |h,k| h[k] = 1 }.tap do |multipliers|
        requested_multipliers = order.request_options.try(:[], :multiplier) || {}
        requested_multipliers.each { |k,v| multipliers[k.to_s] = v.to_i }
      end
    end

  end

  ##
  # Builds all requests of a given request type and any target_assets
  # The build! method automatically creates a link of the appropriate class
  module ChainLink

    def self.included(base)
      base.class_eval do
        attr_reader :request_type, :multiplier, :source_assets, :target_assets, :chain
      end
    end

    def self.build!(request_type,multiplier,assets,chain)
      link_class = request_type.for_multiplexing? ? MultiplexedLink : UnplexedLink
      link_class.new(request_type,multiplier,assets,chain).tap do |link|
        link.build!
        link.target_assets
      end
    end

    def initialize(request_type,multiplier,source_assets,chain)
      @request_type   = request_type
      @multiplier     = multiplier
      @source_assets  = source_assets
      @chain          = chain
    end

    def multiplexed?; false; end

    def build!
      multiplier.times do |_|
        # Now we can iterate over the source assets and target assets building the requests between them.
        # Ensure that the request has the correct comments on it, and that the aliquots of the source asset
        # are transferred into the destination if the request does not do this in some manner itself.
        source_asset_target_assets do |source_asset, target_asset|

          chain.order.create_request_of_type!(
            request_type,
            :asset => source_asset, :target_asset => target_asset
          ).tap do |request|

            AssetLink.create_edge!(source_asset, target_asset) if source_asset.present? and target_asset.present?

            comments.each do |comment|
              request.comments.create!(:user => user, :description => comment)
            end if comments.present?
          end
        end
      end
      associate_built_requests!
    end

    private

    def comments
      chain.order.comments
    end

    def user
      chain.order.user
    end

    def source_asset_target_assets
      new_target_assets = generate_target_assets
      source_assets_with_index do |source_asset,index|
        yield(source_asset,new_target_assets[index])
      end
    end

    def associate_built_requests!
      #Do Nothing
    end

    def create_target_asset(source_asset = nil)
      request_type.create_target_asset! do |asset|
        asset.generate_barcode
        asset.generate_name(source_asset.try(:name) || asset.barcode.to_s)
      end
    end
  end

  class MultiplexedLink
    include ChainLink

    def initialize(request_type,multiplier,assets,chain)
      raise RequestChainError unless request_type.for_multiplexing?
      raise RequestChainError, 'Cannot multiply multiplexed requests' if multiplier > 1
      super
    end

    def multiplexed?; true; end

    private

    def source_assets_with_index
      source_assets.each do |asset|
        yield(asset,request_type.pool_index_for_asset(asset))
      end
    end

    # We can only do this once for multiplexed request types
    def generate_target_assets
      @target_assets ||= chain.multiplexing_assets do
        # We yield only if we don't have any multiplexing assets
        request_type.pool_count.times.map { create_target_asset }
      end
    end

    def associate_built_requests!
      downstream_requests.each do |request|
        request.update_attributes!(:initial_study => nil) if request.initial_study != study
        request.update_attributes!(:initial_project => nil) if request.initial_project != project
        comments.each do |comment|
          request.comments.create!(:user => user, :description => comment)
        end if comments.present?
      end
    end

    def downstream_requests
      target_assets.uniq.compact.map(&:requests).flatten
    end

  end

  class UnplexedLink
    include ChainLink

    def initialize(request_type,multiplier,assets,chain)
      raise RequestChainError if request_type.for_multiplexing?
      super
    end

    def generate_target_assets
      source_assets.map do |source_asset|
        create_target_asset(source_asset)
      end.tap do |new_target_assets|
        @target_assets ||= []
        @target_assets.concat(new_target_assets)
      end
    end

    def source_assets_with_index(&block)
      source_assets.each_with_index(&block)
    end
  end

  module OrderMethods

    def build_request_graph!(multiplexing_assets = nil, &block)
      ActiveRecord::Base.transaction do
        RequestChain.new(self,assets, multiplexing_assets).tap do |chain|
          chain.build!
          yield chain.multiplexing_assets if chain.multiplexed?
        end
      end
    end

  end

end
