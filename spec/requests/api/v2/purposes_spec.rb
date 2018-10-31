# frozen_string_literal: true

require 'rails_helper'

describe 'Purposes API', with: :api_v2 do
  context 'with multiple purposes' do
    before do
      create(:purpose)
      create(:plate_purpose)
      create(:tube_purpose)
    end

    it 'sends a list of purposes' do
      api_get '/api/v2/purposes'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(Purpose.count)
    end

    # Check filters, ESPECIALLY if they aren't simple attribute filters
  end

  context 'with a purpose' do
    let(:resource_model) { create :purpose }

    it 'sends an individual purpose' do
      api_get "/api/v2/purposes/#{resource_model.id}"
      expect(response).to have_http_status(:success)
      expect(json.dig('data', 'type')).to eq('purposes')
    end
  end
end