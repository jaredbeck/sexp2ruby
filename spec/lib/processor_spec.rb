require 'ruby_parser'

module Sexp2Ruby
  RSpec.describe Processor do
    let(:processor) { described_class.new }
    let(:processor_hash19) { described_class.new(hash_syntax: :ruby19) }

    describe "#new" do
      it "accepts hash_syntax option" do
        expect(processor_hash19.hash_syntax).to eq(:ruby19)
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

    describe "#process" do
      context "hash" do
        it "ruby19_one_pair" do
          inp = s(:hash, s(:lit, :foo), s(:str, "bar"))
          compare(inp, '{ foo: "bar" }', processor_hash19)
        end

        it "ruby19_when_key_has_special_chars" do
          inp = s(:hash, s(:str, "hurr:durr"), s(:str, "bar"))
          compare(inp, '{ "hurr:durr" => "bar" }', processor_hash19)
        end

        it "ruby19_when_key_is_not_a_literal" do
          inp = s(:hash, s(:call, nil, :foo, s(:str, "bar")), s(:str, "baz"))
          compare(inp, '{ foo("bar") => "baz" }', processor_hash19)
        end

        it "ruby19_mixed_pairs" do
          inp = s(:hash, s(:lit, :foo), s(:str, "bar"), s(:lit, 0.7), s(:str, "baz"))
          compare(inp, '{ foo: "bar", 0.7 => "baz" }', processor_hash19)
        end
      end
    end

    describe "#ruby19_hash_key?" do
      context "symbol" do
        it "returns true" do
          expect(processor.ruby19_hash_key?(s(:lit, :foo))).to eq(true)
        end
      end

      context "not a symbol" do
        it "returns false" do
          expect(processor.ruby19_hash_key?(s(:str, "foo"))).to eq(false)
          expect(processor.ruby19_hash_key?(s(:lit, 7))).to eq(false)
          expect(processor.ruby19_hash_key?(s(:true))).to eq(false)
        end
      end
    end

    def compare(sexp, expected_ruby, processor, check_sexp = true, expected_eval = nil)
      if check_sexp
        expect(RubyParser.new.process(expected_ruby)).to eq(sexp)
      end
      expect(processor.process(sexp)).to eq(expected_ruby)
      if expected_eval
        expect(eval(expected_ruby)).to eq(expected_eval)
      end
    end

  end
end
