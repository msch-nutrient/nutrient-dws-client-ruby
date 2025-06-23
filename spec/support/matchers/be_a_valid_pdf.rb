# frozen_string_literal: true

RSpec::Matchers.define :be_a_valid_pdf do
  match do |actual|
    actual.is_a?(String) && actual.start_with?('%PDF')
  end

  failure_message do |actual|
    "expected a binary string starting with '%PDF', but got #{actual.class}"
  end

  failure_message_when_negated do |actual|
    "expected not to be a valid PDF, but got a string starting with '%PDF'"
  end

  description do
    "be a valid PDF (binary string starting with '%PDF')"
  end
end