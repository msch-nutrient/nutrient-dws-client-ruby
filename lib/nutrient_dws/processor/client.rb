# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'securerandom'

module NutrientDWS
  module Processor
    class Client
      API_BASE_URL = 'https://api.nutrient.io'
      API_ENDPOINT = '/build'

      def initialize(api_key:)
        raise ArgumentError, 'API key is required' if api_key.nil? || api_key.empty?

        @api_key = api_key
        @boundary = SecureRandom.hex(16)
      end

      def convert(file:, to:)
        instructions = {
          parts: [
            build_part(file, 'document')
          ]
        }

        # Add output format specification
        case to.downcase
        when 'pdf'
          # PDF is the default, no output section needed
        when 'png', 'jpg', 'jpeg', 'webp', 'tiff'
          instructions[:output] = {
            type: 'image',
            format: to.downcase,
            dpi: 300
          }
        when 'docx'
          instructions[:output] = {
            type: 'docx'
          }
        when 'xlsx'
          instructions[:output] = {
            type: 'xlsx'
          }
        when 'pptx'
          instructions[:output] = {
            type: 'pptx'
          }
        else
          raise ArgumentError,
                "Unsupported output format: #{to}. Supported formats: pdf, png, jpg, jpeg, webp, tiff, docx, xlsx, pptx"
        end

        make_request(instructions, files: { 'document' => file })
      end

      def ocr(file:, language: 'eng')
        instructions = {
          parts: [
            build_part(file, 'document')
          ],
          actions: [
            {
              type: 'ocr',
              language: language
            }
          ]
        }

        make_request(instructions, files: { 'document' => file })
      end

      def watermark(file:, text: nil, image: nil, **options)
        raise ArgumentError, 'Either text or image must be provided' if text.nil? && image.nil?

        parts = [build_part(file, 'document')]
        files = { 'document' => file }

        # Build watermark action with required width/height
        watermark_action = {
          type: 'watermark',
          width: options[:width] || 200,
          height: options[:height] || 50
        }

        if text
          watermark_action[:text] = text
          # Add text-specific options
          watermark_action[:fontSize] = options[:font_size] if options[:font_size]
          watermark_action[:fontFamily] = options[:font_family] if options[:font_family]
          watermark_action[:fontColor] = options[:font_color] if options[:font_color]
        elsif image
          parts << build_part(image, 'watermark_image')
          files['watermark_image'] = image
          watermark_action[:image] = 'watermark_image'
        end

        # Add positioning and styling options
        watermark_action[:opacity] = options[:opacity] if options[:opacity]
        watermark_action[:rotation] = options[:rotation] if options[:rotation]
        watermark_action[:top] = options[:top] if options[:top]
        watermark_action[:left] = options[:left] if options[:left]
        watermark_action[:right] = options[:right] if options[:right]
        watermark_action[:bottom] = options[:bottom] if options[:bottom]

        instructions = {
          parts: parts,
          actions: [watermark_action]
        }

        make_request(instructions, files: files)
      end

      def merge(files:)
        parts = []
        file_map = {}

        files.each_with_index do |file, index|
          file_key = "file_#{index}"
          parts << build_part(file, file_key)
          file_map[file_key] = file
        end

        instructions = {
          parts: parts
          # No actions needed - multiple parts are automatically merged
        }

        make_request(instructions, files: file_map)
      end

      def split(file:, ranges:)
        # For splitting, we specify page ranges in the part itself
        part = build_part(file, 'document')

        # Add pageIndexes to specify which pages to include
        page_indexes = parse_page_ranges(ranges)
        if !url?(file)
          part[:pageIndexes] = page_indexes
        else
          # For URLs, modify the part structure
          part[:file][:pageIndexes] = page_indexes
        end

        instructions = {
          parts: [part]
        }

        make_request(instructions, files: { 'document' => file })
      end

      def redact(file:, text: [])
        parts = [build_part(file, 'document')]
        actions = []

        # Create a redaction action for each text term
        text.each do |term|
          actions << {
            type: 'createRedactions',
            strategy: 'text',
            strategyOptions: {
              text: term
            }
          }
        end

        # Apply all redactions at the end
        actions << { type: 'applyRedactions' }

        instructions = {
          parts: parts,
          actions: actions
        }

        make_request(instructions, files: { 'document' => file })
      end

      private

      def parse_page_ranges(ranges)
        # Convert range string like "1,3-5,10" to array of 0-based page indexes
        page_indexes = []
        ranges.split(',').each do |range|
          range = range.strip
          if range.include?('-')
            start_page, end_page = range.split('-').map(&:to_i)
            (start_page..end_page).each { |page| page_indexes << page - 1 }
          else
            page_indexes << range.to_i - 1
          end
        end
        page_indexes
      end

      def build_part(file, file_key)
        if url?(file)
          { file: { url: file.to_s } }
        else
          { file: file_key }
        end
      end

      def url?(file)
        file.to_s.match?(%r{\Ahttps?://})
      end

      def make_request(instructions, files: {})
        uri = URI("#{API_BASE_URL}#{API_ENDPOINT}")

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(uri)
        request['Authorization'] = "Bearer #{@api_key}"

        if files.any? { |_, file| !url?(file) }
          # Use multipart form data for file uploads
          request['Content-Type'] = "multipart/form-data; boundary=#{@boundary}"
          request.body = build_multipart_body(instructions, files)
        else
          # Use JSON for URL-only requests
          request['Content-Type'] = 'application/json'
          request.body = instructions.to_json
        end

        response = http.request(request)
        handle_response(response)
      end

      def build_multipart_body(instructions, files)
        body = []

        # Add instructions
        body << "--#{@boundary}"
        body << 'Content-Disposition: form-data; name="instructions"'
        body << 'Content-Type: application/json'
        body << ''
        body << instructions.to_json

        # Add files
        files.each do |file_key, file|
          next if url?(file)

          file_content = read_file(file)
          filename = extract_filename(file)

          body << "--#{@boundary}"
          body << %(Content-Disposition: form-data; name="#{file_key}"; filename="#{filename}")
          body << 'Content-Type: application/octet-stream'
          body << ''
          body << file_content
        end

        body << "--#{@boundary}--"
        body.join("\r\n")
      end

      def read_file(file)
        case file
        when String
          File.binread(file)
        when File, IO
          file.read
        else
          raise ArgumentError, "Unsupported file type: #{file.class}"
        end
      end

      def extract_filename(file)
        case file
        when String
          File.basename(file)
        when File
          File.basename(file.path)
        else
          'document'
        end
      end

      def handle_response(response)
        case response.code.to_i
        when 200, 201
          response.body
        when 401
          raise NutrientDWS::AuthenticationError, 'Invalid or missing API key'
        else
          # Add debugging info to error message
          error_details = ''
          begin
            parsed_error = JSON.parse(response.body)
            if parsed_error['error'] && parsed_error['error']['failingPaths']
              error_details = "\nAPI Error Details:\n"
              parsed_error['error']['failingPaths'].each do |path_error|
                error_details += "  #{path_error['path']}: #{path_error['details']}\n"
              end
            end
          rescue JSON::ParserError
            # If we can't parse the error, just include the raw body
            error_details = "\nRaw response: #{response.body}"
          end

          raise NutrientDWS::APIError.new(
            "API request failed: #{response.message}#{error_details}",
            status_code: response.code.to_i,
            response_body: response.body
          )
        end
      end
    end
  end
end
