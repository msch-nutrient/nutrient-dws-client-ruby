# **nutrient-dws Ruby Client Library Specification**

## **1\. Introduction**

This document outlines the design and functionality of the nutrient-dws Ruby gem, a client library for interacting with the Nutrient DWS Processor API. The library provides a clean, idiomatic Ruby interface for all of the API's document processing capabilities.

**Key Design Principles:**

* **Ease of Use:** Offer a simple and intuitive interface for common use cases.  
* **Clarity:** Ensure that the library's behavior is predictable and well-documented.  
* **Robustness:** Implement comprehensive error handling to manage API responses gracefully.

**Namespace:** All library code will reside within the NutrientDWS::Processor namespace.

## **2\. Gem Installation**

The gem should be packaged and distributed via RubyGems.org. It can be added to a project's Gemfile:

\# Gemfile  
gem 'nutrient-dws'

And installed using Bundler:

bundle install

## **3\. Configuration and Initialization**

The primary entry point for the library is the NutrientDWS::Processor::Client class. It is initialized with an API key, which is used to authenticate all requests.

### **Client Initialization**

require 'nutrient\_dws/processor'

\# Create a new client instance  
client \= NutrientDWS::Processor::Client.new(api\_key: 'YOUR\_NUTRIENT\_API\_KEY')

The client object will be responsible for handling all HTTP communication with the Nutrient DWS API, including authentication headers and error handling.

## **4\. Error Handling**

The library must provide a clear mechanism for handling API errors. All API-related exceptions should inherit from a base NutrientDWS::Error class.

### **Custom Exception Classes**

* **NutrientDWS::Error**: The base class for all library-specific errors.  
* **NutrientDWS::AuthenticationError**: Raised for 401 Unauthorized responses, indicating an invalid or missing API key.  
* **NutrientDWS::APIError**: Raised for other non-2xx HTTP responses (e.g., 400, 429, 5xx). This exception should provide access to the HTTP status code and the response body from the API for debugging.

Methods that make API calls should raise one of these exceptions upon failure.

**Example:**

begin  
  client.convert(file: 'non\_existent\_file.docx', to: 'pdf')  
rescue NutrientDWS::APIError \=\> e  
  puts "An API error occurred: \#{e.message}"  
  puts "HTTP Status: \#{e.status\_code}"  
  puts "Response Body: \#{e.response\_body}"  
rescue NutrientDWS::AuthenticationError \=\> e  
  puts "Please check your API key."  
rescue Errno::ENOENT \=\> e  
  puts "File not found: \#{e.message}"  
end

## **5\. API Methods**

The library provides simple, direct methods for performing single document processing operations. Each method corresponds to a specific API tool and wraps the /build endpoint to provide a straightforward experience.

The file or files parameter in these methods should accept a local file path (String), a File object, or a remote URL (String). The library will be responsible for reading the file content or passing the URL to the API as required.

The return value for methods that produce a document should be the binary content of the resulting file as a String.

### **Methods**

#### **File Conversion**

* convert(file:, to:)  
  * Converts a single file to a different format.  
  * **Parameters:**  
    * file: The source file to convert.  
    * to (String): The target format (e.g., 'pdf', 'png', 'docx').  
  * **Returns:** Binary file content (String).

\# Example: Convert a DOCX to PDF  
pdf\_data \= client.convert(file: 'path/to/document.docx', to: 'pdf')  
File.binwrite('output.pdf', pdf\_data)

#### **OCR**

* ocr(file:, language: 'eng')  
  * Performs Optical Character Recognition on a document to create a searchable PDF.  
  * **Parameters:**  
    * file: The source file (e.g., a scanned PDF or image).  
    * language (String): The language of the text.  
  * **Returns:** Binary PDF content (String).

\# Example: OCR a scanned image  
searchable\_pdf \= client.ocr(file: 'path/to/scan.png', language: 'eng')  
File.binwrite('searchable.pdf', searchable\_pdf)

#### **Watermarking**

* watermark(file:, text: nil, image: nil, \*\*options)  
  * Adds a text or image watermark to a PDF.  
  * **Parameters:**  
    * file: The source PDF file.  
    * text (String): The text to use for the watermark.  
    * image (File path/URL): The image to use for the watermark.  
    * options: A Hash of additional styling options (e.g., font\_size, opacity, rotation).  
  * **Returns:** Binary PDF content (String).

\# Example: Add a text watermark  
watermarked\_pdf \= client.watermark(file: 'report.pdf', text: 'CONFIDENTIAL')  
File.binwrite('watermarked.pdf', watermarked\_pdf)

#### **PDF Editing**

* merge(files:)  
  * Merges multiple documents into a single PDF.  
  * **Parameters:**  
    * files (Array): An array of source files to merge in order.  
  * **Returns:** Binary PDF content (String).  
* split(file:, ranges:)  
  * Splits a PDF into multiple pages or ranges.  
  * **Parameters:**  
    * file: The source PDF file.  
    * ranges (String): A string specifying the pages to select (e.g., '1,3-5').  
  * **Returns:** Binary PDF content (String).  
* redact(file:, text: \[\])  
  * Redacts text from a PDF.  
  * **Parameters:**  
    * file: The source PDF.  
    * text (Array of Strings): A list of text strings to find and redact.  
  * **Returns:** Binary PDF content (String).

## **6\. Testing Strategy**

The gem must have a robust test suite to ensure its correctness and reliability. The primary focus will be on **integration tests** that run against the live Nutrient DWS Processor API.

### **Setup**

* **Test Framework:** RSpec is recommended.  
* **API Key Management:** The test suite will require a valid NUTRIENT\_API\_KEY. This key should be loaded from an .env file at the root of the project and should not be committed to version control.  
* **Sample Files:** A spec/fixtures directory will contain sample files for testing, including at least one .pdf and one .docx file.

### **Test Helpers**

To keep tests clean and readable, a custom RSpec matcher should be defined for PDF validation.

\# spec/support/matchers/be\_a\_valid\_pdf.rb  
RSpec::Matchers.define :be\_a\_valid\_pdf do  
  match do |actual|  
    actual.is\_a?(String) && actual.start\_with?('%PDF')  
  end

  failure\_message do |actual|  
    "expected a binary string starting with '%PDF', but got \#{actual.class}"  
  end  
end

This helper can then be loaded in spec/spec\_helper.rb.

### **Assertions**

For any test that generates a PDF, the test should assert two things:

1. The API call was successful (i.e., it did not raise an exception).  
2. The returned binary data is a valid PDF, using the custom matcher.

### **Test Cases**

Each method in the API should have at least one corresponding integration test.

\# spec/client\_spec.rb  
RSpec.describe NutrientDWS::Processor::Client do  
  let(:client) { described\_class.new(api\_key: ENV.fetch('NUTRIENT\_API\_KEY')) }  
  let(:docx\_file) { 'spec/fixtures/sample.docx' }  
  let(:pdf\_file) { 'spec/fixtures/sample.pdf' }

  describe '\#convert' do  
    it 'successfully converts a DOCX to PDF' do  
      pdf\_result \= client.convert(file: docx\_file, to: 'pdf')  
      expect(pdf\_result).to be\_a\_valid\_pdf  
    end  
  end

  describe '\#merge' do  
    it 'successfully merges two documents' do  
      pdf\_result \= client.merge(files: \[pdf\_file, docx\_file\])  
      expect(pdf\_result).to be\_a\_valid\_pdf  
    end  
  end  
end

This testing strategy ensures the library is validated against the real API, providing high confidence in its functionality.
