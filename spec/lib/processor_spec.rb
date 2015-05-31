module Sexp2Ruby
  RSpec.describe Processor do
    describe "#new" do
      it "accepts hash_syntax option" do
        processor = described_class.new(hash_syntax: :ruby19)
        expect(processor.hash_syntax).to eq(:ruby19)
      end

      context "unknown option" do
        it "raises error" do
          expect {
            described_class.new(foo: "bar")
          }.to raise_error(InvalidOption)
        end
      end

      context "bad option value" do
        it "raises error" do
          expect {
            described_class.new(hash_syntax: "banana")
          }.to raise_error(InvalidOption)
        end
      end
    end

    describe "#extract_option" do
      let(:processor) { described_class.new }

      context "valid value" do
        it "returns value" do
          expect(
            processor.extract_option([:a, :b], :b, :c)
          ).to eq(:b)
        end
      end

      context "nil value" do
        it "returns default value" do
          expect(
            processor.extract_option([:a, :b], nil, :c)
          ).to eq(:c)
        end
      end

      context "invalid value" do
        it "raises error" do
          expect {
            processor.extract_option([:a, :b], :d, :c)
          }.to raise_error(InvalidOption)
        end
      end
    end
  end
end
