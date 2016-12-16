module Accession
  class Request

    include ActiveModel::Validations

    attr_reader :submission, :resource

    validates_presence_of :submission

    class_attribute :rest_client
    self.rest_client = RestClient::Resource

    def self.post(submission)
      new(submission).post
    end

    def initialize(submission)
      @submission = submission

      if valid?
        @resource = rest_client.new(submission.service.url)
        set_proxy
      end
    end

    def post
      if valid?
        begin
          Accession::Response.new(resource.post(submission.payload.open))
        rescue StandardError => exception
          Accession::NullResponse.new
        ensure
          submission.payload.destroy
        end
      end
    end

  private

    def set_proxy
      if configatron.disable_web_proxy
        RestClient.proxy = ''
      else
        if configatron.proxy 
          RestClient.proxy = configatron.proxy
          resource.options[:headers] = { user_agent: "Sequencescape Accession Client (#{Rails.env})" }
        end
      end
    end

  end
end