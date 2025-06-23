# frozen_string_literal: true

RSpec.describe NutrientDWS::Error do
  describe 'inheritance hierarchy' do
    it 'is a StandardError' do
      expect(described_class).to be < StandardError
    end
  end
end

RSpec.describe NutrientDWS::AuthenticationError do
  describe 'inheritance hierarchy' do
    it 'inherits from NutrientDWS::Error' do
      expect(described_class).to be < NutrientDWS::Error
    end
  end

  describe 'initialization' do
    it 'can be created with a message' do
      error = described_class.new('Invalid API key')
      expect(error.message).to eq('Invalid API key')
    end
  end
end

RSpec.describe NutrientDWS::APIError do
  describe 'inheritance hierarchy' do
    it 'inherits from NutrientDWS::Error' do
      expect(described_class).to be < NutrientDWS::Error
    end
  end

  describe 'initialization' do
    it 'can be created with just a message' do
      error = described_class.new('API error occurred')
      expect(error.message).to eq('API error occurred')
      expect(error.status_code).to be_nil
      expect(error.response_body).to be_nil
    end

    it 'can be created with status code and response body' do
      error = described_class.new(
        'Bad request',
        status_code: 400,
        response_body: '{"error": "Invalid parameter"}'
      )

      expect(error.message).to eq('Bad request')
      expect(error.status_code).to eq(400)
      expect(error.response_body).to eq('{"error": "Invalid parameter"}')
    end
  end

  describe 'attributes' do
    let(:error) do
      described_class.new(
        'Server error',
        status_code: 500,
        response_body: 'Internal server error'
      )
    end

    it 'provides read access to status_code' do
      expect(error.status_code).to eq(500)
    end

    it 'provides read access to response_body' do
      expect(error.response_body).to eq('Internal server error')
    end
  end
end
