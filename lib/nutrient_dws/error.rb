# frozen_string_literal: true

module NutrientDWS
  # Base class for all library-specific errors
  class Error < StandardError; end

  # Raised for 401 Unauthorized responses, indicating an invalid or missing API key
  class AuthenticationError < Error; end

  # Raised for other non-2xx HTTP responses (e.g., 400, 429, 5xx)
  # This exception provides access to the HTTP status code and response body for debugging
  class APIError < Error
    attr_reader :status_code, :response_body

    def initialize(message, status_code: nil, response_body: nil)
      super(message)
      @status_code = status_code
      @response_body = response_body
    end
  end
end