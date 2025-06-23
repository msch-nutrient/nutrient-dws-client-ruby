# Nutrient DWS Ruby Client

A Ruby client library for interacting with the [Nutrient DWS Processor API](https://www.nutrient.io/api/). This gem provides a clean, idiomatic Ruby interface for document processing operations including conversion, OCR, watermarking, and PDF editing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'nutrient-dws'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install nutrient-dws
```

## Prerequisites

- Ruby 2.7 or higher
- A Nutrient DWS API key (get one at [Nutrient Dashboard](https://dashboard.nutrient.io/))

## Quick Start

```ruby
require 'nutrient_dws/processor'

# Initialize the client with your API key
client = NutrientDWS::Processor::Client.new(api_key: 'YOUR_NUTRIENT_API_KEY')

# Convert a DOCX file to PDF
pdf_data = client.convert(file: 'document.docx', to: 'pdf')
File.binwrite('output.pdf', pdf_data)
```

## Configuration

### Environment Variables

You can set your API key using an environment variable:

```bash
export NUTRIENT_API_KEY=your_api_key_here
```

Then initialize the client without passing the key explicitly:

```ruby
client = NutrientDWS::Processor::Client.new(api_key: ENV['NUTRIENT_API_KEY'])
```

## Usage

### File Conversion

Convert documents between different formats:

```ruby
# Convert DOCX to PDF
pdf_data = client.convert(file: 'document.docx', to: 'pdf')
File.binwrite('output.pdf', pdf_data)

# Convert PDF to PNG
png_data = client.convert(file: 'document.pdf', to: 'png')
File.binwrite('output.png', png_data)

# Using a File object
File.open('document.docx', 'rb') do |file|
  pdf_data = client.convert(file: file, to: 'pdf')
  File.binwrite('output.pdf', pdf_data)
end

# Using a remote URL
pdf_data = client.convert(file: 'https://example.com/document.docx', to: 'pdf')
File.binwrite('output.pdf', pdf_data)
```

### OCR (Optical Character Recognition)

Make scanned documents searchable:

```ruby
# Perform OCR on an image (default language: English)
searchable_pdf = client.ocr(file: 'scanned_document.png')
File.binwrite('searchable.pdf', searchable_pdf)

# Specify a different language
searchable_pdf = client.ocr(file: 'document_francais.png', language: 'fra')
File.binwrite('searchable.pdf', searchable_pdf)
```

### Watermarking

Add text or image watermarks to PDFs:

```ruby
# Add a text watermark
watermarked_pdf = client.watermark(file: 'document.pdf', text: 'CONFIDENTIAL')
File.binwrite('watermarked.pdf', watermarked_pdf)

# Add text watermark with styling options
watermarked_pdf = client.watermark(
  file: 'document.pdf',
  text: 'DRAFT',
  font_size: 72,
  opacity: 0.5,
  rotation: 45
)
File.binwrite('watermarked.pdf', watermarked_pdf)

# Add an image watermark
watermarked_pdf = client.watermark(file: 'document.pdf', image: 'logo.png')
File.binwrite('watermarked.pdf', watermarked_pdf)
```

### PDF Editing

#### Merge Documents

Combine multiple documents into a single PDF:

```ruby
# Merge multiple files
merged_pdf = client.merge(files: ['doc1.pdf', 'doc2.docx', 'image.png'])
File.binwrite('merged.pdf', merged_pdf)

# Files are merged in the order provided
merged_pdf = client.merge(files: ['cover.pdf', 'content.docx', 'appendix.pdf'])
File.binwrite('complete_document.pdf', merged_pdf)
```

#### Split PDF

Extract specific pages from a PDF:

```ruby
# Extract first page only
first_page = client.split(file: 'document.pdf', ranges: '1')
File.binwrite('first_page.pdf', first_page)

# Extract multiple pages and ranges
selected_pages = client.split(file: 'document.pdf', ranges: '1,3-5,10')
File.binwrite('selected_pages.pdf', selected_pages)
```

#### Redact Text

Remove sensitive information from PDFs:

```ruby
# Redact specific text
redacted_pdf = client.redact(
  file: 'sensitive_document.pdf',
  text: ['Social Security', 'confidential', 'secret']
)
File.binwrite('redacted.pdf', redacted_pdf)
```

## Error Handling

The library provides specific exception classes for different types of errors:

```ruby
begin
  pdf_data = client.convert(file: 'document.docx', to: 'pdf')
rescue NutrientDWS::AuthenticationError => e
  puts "Authentication failed: #{e.message}"
  puts "Please check your API key"
rescue NutrientDWS::APIError => e
  puts "API error occurred: #{e.message}"
  puts "HTTP Status: #{e.status_code}"
  puts "Response Body: #{e.response_body}"
rescue Errno::ENOENT => e
  puts "File not found: #{e.message}"
end
```

### Error Classes

- `NutrientDWS::Error`: Base class for all library-specific errors
- `NutrientDWS::AuthenticationError`: Raised for 401 Unauthorized responses
- `NutrientDWS::APIError`: Raised for other non-2xx HTTP responses, provides access to `status_code` and `response_body`

## Supported File Types

### Input Formats
- PDF
- Microsoft Office (DOCX, XLSX, PPTX)
- Images (PNG, JPEG, TIFF)
- HTML
- And many more...

### Output Formats
- PDF
- Images (PNG, JPEG, TIFF)
- Microsoft Office formats
- And many more...

For a complete list of supported formats, see the [Nutrient API documentation](https://www.nutrient.io/api/tools-overview/).

## Development

After checking out the repo, run `bundle install` to install dependencies.

### Running Tests

The test suite includes both unit tests and integration tests. Integration tests require a valid API key.

1. Copy the environment file and add your API key:
   ```bash
   cp .env.example .env
   # Edit .env and add your NUTRIENT_API_KEY
   ```

2. Add test fixtures:
   ```bash
   # Add sample files to spec/fixtures/
   # - sample.pdf
   # - sample.docx  
   # - sample.png
   ```

3. Run the tests:
   ```bash
   bundle exec rspec
   ```

To run only unit tests (without API key):
```bash
bundle exec rspec --tag ~integration
```

To run the linter:
```bash
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/nutrient-io/nutrient-dws-ruby](https://github.com/nutrient-io/nutrient-dws-ruby).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Support

- [Nutrient API Documentation](https://www.nutrient.io/api/documentation/)
- [Nutrient Support](https://www.nutrient.io/support/)
- [GitHub Issues](https://github.com/nutrient-io/nutrient-dws-ruby/issues)