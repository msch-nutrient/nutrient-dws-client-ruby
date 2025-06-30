# frozen_string_literal: true

RSpec.describe NutrientDWS::Processor::Client, :integration do
  let(:client) { described_class.new(api_key: ENV.fetch('NUTRIENT_API_KEY')) }
  let(:docx_file) { 'spec/fixtures/sample.docx' }
  let(:pdf_file) { 'spec/fixtures/sample.pdf' }
  let(:image_file) { 'spec/fixtures/sample.png' }

  describe '#initialize' do
    it 'creates a client with an API key' do
      expect(client).to be_a(described_class)
    end

    it 'raises an error when API key is missing' do
      expect { described_class.new(api_key: nil) }.to raise_error(ArgumentError)
    end
  end

  describe '#convert' do
    context 'when converting DOCX to PDF' do
      it 'successfully converts a DOCX to PDF' do
        skip 'sample.docx fixture not found' unless File.exist?(docx_file)

        pdf_result = client.convert(file: docx_file, to: 'pdf')
        expect(pdf_result).to be_a_valid_pdf
      end
    end

    context 'when converting PDF to PNG' do
      it 'successfully converts a PDF to PNG' do
        skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

        png_result = client.convert(file: pdf_file, to: 'png')
        expect(png_result).to be_a(String)
        expect(png_result).not_to be_empty
      end
    end

    context 'with File object' do
      it 'accepts a File object as input' do
        skip 'sample.docx fixture not found' unless File.exist?(docx_file)

        File.open(docx_file, 'rb') do |file|
          pdf_result = client.convert(file: file, to: 'pdf')
          expect(pdf_result).to be_a_valid_pdf
        end
      end
    end

    context 'with invalid parameters' do
      it 'raises an error for non-existent file' do
        expect do
          client.convert(file: 'non_existent_file.docx', to: 'pdf')
        end.to raise_error(Errno::ENOENT)
      end

      it 'raises an error for unsupported output format' do
        skip 'sample.docx fixture not found' unless File.exist?(docx_file)

        expect do
          client.convert(file: docx_file, to: 'unsupported_format')
        end.to raise_error(ArgumentError, /Unsupported output format/)
      end
    end
  end

  describe '#ocr' do
    it 'successfully performs OCR on an image' do
      skip 'sample.png fixture not found' unless File.exist?(image_file)

      searchable_pdf = client.ocr(file: image_file, language: 'eng')
      expect(searchable_pdf).to be_a_valid_pdf
    end

    it 'accepts custom language parameter' do
      skip 'sample.png fixture not found' unless File.exist?(image_file)

      searchable_pdf = client.ocr(file: image_file, language: 'fra')
      expect(searchable_pdf).to be_a_valid_pdf
    end
  end

  describe '#watermark' do
    context 'with text watermark' do
      it 'successfully adds a text watermark to PDF' do
        skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

        watermarked_pdf = client.watermark(file: pdf_file, text: 'CONFIDENTIAL')
        expect(watermarked_pdf).to be_a_valid_pdf
      end

      it 'accepts styling options' do
        skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

        watermarked_pdf = client.watermark(
          file: pdf_file,
          text: 'DRAFT',
          font_size: 72,
          opacity: 0.5,
          rotation: 45
        )
        expect(watermarked_pdf).to be_a_valid_pdf
      end
    end

    context 'with image watermark' do
      it 'successfully adds an image watermark to PDF' do
        skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)
        skip 'sample.png fixture not found' unless File.exist?(image_file)

        watermarked_pdf = client.watermark(file: pdf_file, image: image_file)
        expect(watermarked_pdf).to be_a_valid_pdf
      end
    end

    context 'with invalid parameters' do
      it 'raises an error when neither text nor image is provided' do
        skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

        expect do
          client.watermark(file: pdf_file)
        end.to raise_error(ArgumentError, 'Either text or image must be provided')
      end
    end
  end

  describe '#merge' do
    it 'successfully merges two documents' do
      skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)
      skip 'sample.docx fixture not found' unless File.exist?(docx_file)

      pdf_result = client.merge(files: [pdf_file, docx_file])
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully merges multiple documents' do
      skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

      pdf_result = client.merge(files: [pdf_file, pdf_file, pdf_file])
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'accepts mixed file types' do
      skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)
      skip 'sample.png fixture not found' unless File.exist?(image_file)

      pdf_result = client.merge(files: [pdf_file, image_file])
      expect(pdf_result).to be_a_valid_pdf
    end
  end

  describe '#split' do
    it 'successfully splits a PDF by page ranges' do
      skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

      pdf_result = client.split(file: pdf_file, ranges: '1')
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'handles complex page ranges' do
      skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

      pdf_result = client.split(file: pdf_file, ranges: '1,3-5')
      expect(pdf_result).to be_a_valid_pdf
    end
  end

  describe '#redact' do
    it 'successfully redacts text from a PDF' do
      skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

      redacted_pdf = client.redact(file: pdf_file, text: %w[confidential secret])
      expect(redacted_pdf).to be_a_valid_pdf
    end

    it 'handles empty text array' do
      skip 'sample.pdf fixture not found' unless File.exist?(pdf_file)

      redacted_pdf = client.redact(file: pdf_file, text: [])
      expect(redacted_pdf).to be_a_valid_pdf
    end
  end

  describe 'error handling' do
    let(:invalid_client) { described_class.new(api_key: 'invalid_key') }

    it 'raises AuthenticationError for invalid API key' do
      skip 'sample.docx fixture not found' unless File.exist?(docx_file)

      expect do
        invalid_client.convert(file: docx_file, to: 'pdf')
      end.to raise_error(NutrientDWS::AuthenticationError, /Invalid or missing API key/)
    end

    it 'provides access to status code and response body in APIError' do
      skip 'sample.docx fixture not found' unless File.exist?(docx_file)

      begin
        invalid_client.convert(file: docx_file, to: 'pdf')
      rescue NutrientDWS::AuthenticationError => e
        # Expected authentication error
        expect(e.message).to include('Invalid or missing API key')
      rescue NutrientDWS::APIError => e
        expect(e.status_code).to be_a(Integer)
        expect(e.response_body).to be_a(String)
      end
    end
  end

  describe '#duplicate_pages' do
    it 'successfully duplicates a single page' do
      pdf_result = client.duplicate_pages(file: pdf_file, page: 0)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully duplicates a page range' do
      pdf_result = client.duplicate_pages(file: pdf_file, start_page: 0, end_page: 0)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully duplicates the entire document' do
      pdf_result = client.duplicate_pages(file: pdf_file)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'handles negative page indexing' do
      pdf_result = client.duplicate_pages(file: pdf_file, page: -1)
      expect(pdf_result).to be_a_valid_pdf
    end
  end

  describe '#delete_pages' do
    it 'successfully deletes a single page' do
      pdf_result = client.delete_pages(file: pdf_file, page: 0)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully deletes a page range' do
      pdf_result = client.delete_pages(file: pdf_file, start_page: 0, end_page: 0)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully keeps pages before a cutoff point' do
      pdf_result = client.delete_pages(file: pdf_file, keep_before: 1)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully keeps pages after a cutoff point' do
      pdf_result = client.delete_pages(file: pdf_file, keep_after: 0)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'raises an error when no deletion criteria provided' do
      expect do
        client.delete_pages(file: pdf_file)
      end.to raise_error(ArgumentError, 'Must specify pages to delete or pages to keep')
    end
  end

  describe '#flatten' do
    it 'successfully flattens a PDF' do
      pdf_result = client.flatten(file: pdf_file)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'accepts File objects' do
      File.open(pdf_file, 'rb') do |file|
        pdf_result = client.flatten(file: file)
        expect(pdf_result).to be_a_valid_pdf
      end
    end
  end

  describe '#rotate' do
    it 'successfully rotates a PDF by 90 degrees' do
      pdf_result = client.rotate(file: pdf_file, rotate_by: 90)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully rotates a PDF by 180 degrees' do
      pdf_result = client.rotate(file: pdf_file, rotate_by: 180)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully rotates a PDF by 270 degrees' do
      pdf_result = client.rotate(file: pdf_file, rotate_by: 270)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'raises an error for invalid rotation angle' do
      expect do
        client.rotate(file: pdf_file, rotate_by: 45)
      end.to raise_error(ArgumentError, /Invalid rotation angle/)
    end
  end

  describe '#add_page' do
    it 'successfully adds a blank page at the beginning' do
      pdf_result = client.add_page(file: pdf_file, position: :beginning)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully adds a blank page at the end' do
      pdf_result = client.add_page(file: pdf_file, position: :end)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully adds multiple blank pages' do
      pdf_result = client.add_page(file: pdf_file, position: :end, page_count: 3)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully adds a page with custom size' do
      pdf_result = client.add_page(file: pdf_file, position: :end, page_size: 'A4')
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully adds a page at a specific position' do
      pdf_result = client.add_page(file: pdf_file, after_page: 0)
      expect(pdf_result).to be_a_valid_pdf
    end
  end

  describe '#set_page_label' do
    it 'successfully sets a label for a single page' do
      pdf_result = client.set_page_label(file: pdf_file, labels: [{ page: 0, label: 'i' }])
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully sets labels for multiple pages' do
      labels = [
        { page: 0, label: 'i' },
        { start_page: 1, end_page: 2, label: '1' }
      ]
      pdf_result = client.set_page_label(file: pdf_file, labels: labels)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully sets labels for page ranges' do
      pdf_result = client.set_page_label(file: pdf_file, labels: [{ start_page: 0, end_page: 1, label: 'Intro' }])
      expect(pdf_result).to be_a_valid_pdf
    end
  end

  describe '#json_import' do
    let(:json_data) do
      {
        "annotations": [
          {
            "bbox": [50, 50, 150, 50],
            "backgroundColor": "#2293FB",
            "createdAt": "1970-01-01T00:00:00Z",
            "id": "test-annotation-001",
            "name": "test-annotation-001",
            "opacity": 1,
            "pageIndex": 0,
            "text": {
              "format": "plain",
              "value": "Test annotation"
            },
            "type": "pspdfkit/text",
            "updatedAt": "1970-01-01T00:00:00Z",
            "v": 2
          }
        ],
        "format": "https://pspdfkit.com/instant-json/v1"
      }.to_json
    end
    let(:json_file) { 'spec/fixtures/annotations.json' }

    it 'successfully imports JSON data to a PDF' do
      pdf_result = client.json_import(file: pdf_file, json_data: json_data)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'accepts JSON data as a file' do
      pdf_result = client.json_import(file: pdf_file, json_file: json_file)
      expect(pdf_result).to be_a_valid_pdf
    end
  end

  describe '#xfdf_import' do
    let(:xfdf_file) { 'spec/fixtures/annotations.xfdf' }

    it 'successfully imports XFDF data to a PDF' do
      pdf_result = client.xfdf_import(file: pdf_file, xfdf_file: xfdf_file)
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'accepts File objects for XFDF data' do
      File.open(xfdf_file, 'rb') do |xfdf|
        pdf_result = client.xfdf_import(file: pdf_file, xfdf_file: xfdf)
        expect(pdf_result).to be_a_valid_pdf
      end
    end
  end

  describe 'remote URL support' do
    let(:remote_pdf_url) { 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf' }

    it 'successfully processes remote URLs (PDF output)' do
      pdf_result = client.convert(file: remote_pdf_url, to: 'pdf')
      expect(pdf_result).to be_a_valid_pdf
    end

    it 'successfully converts remote URLs to image formats' do
      png_result = client.convert(file: remote_pdf_url, to: 'png')
      expect(png_result).to be_a(String)
      expect(png_result).not_to be_empty
    end
  end
end
