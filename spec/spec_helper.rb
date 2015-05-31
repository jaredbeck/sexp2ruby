require "sexp2ruby"

RSpec::Matchers.define :eval_to do |expected|
  match do |actual|
    eval(actual) == expected
  end
  failure_message do |actual|
    "expected #{actual} to evaluate to #{expected}"
  end
end
