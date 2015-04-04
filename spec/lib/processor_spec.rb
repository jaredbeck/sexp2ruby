module Sexp2Ruby
  RSpec.describe Processor do
    describe "#new" do
      it "accepts hash_syntax option" do
        processor = described_class.new(hash_syntax: :ruby19)
        expect(processor.hash_syntax).to eq(:ruby19)
      end
    end
  end
end
