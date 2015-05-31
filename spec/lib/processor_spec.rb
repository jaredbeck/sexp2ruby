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

        describe "parentheses" do
          it "does not wrap string in parens" do
            inp = s(:hash, s(:lit, :k), s(:str, "banana"))
            out = '{ :k => "banana" }'
            compare(inp, out, processor)
          end

          it "does not wrap number in parens" do
            inp = s(:hash, s(:lit, :k), s(:lit, 0.07))
            out = "{ :k => 0.07 }"
            compare(inp, out, processor)
          end

          it "does not wrap boolean in parens" do
            inp = s(:hash, s(:lit, :k), s(:true))
            out = "{ :k => true }"
            compare(inp, out, processor)
          end

          it "does not wrap nil in parens" do
            inp = s(:hash, s(:lit, :k), s(:nil))
            out = "{ :k => nil }"
            compare(inp, out, processor)
          end

          it "does not wrap local variable (lvar) in parens" do
            inp = s(:hash, s(:lit, :k), s(:lvar, :x))
            out = "{ :k => x }"
            compare(inp, out, processor, false)
          end

          it "does not wrap call in parens" do
            inp = s(:hash, s(:lit, :k), s(:call, nil, :foo, s(:lit, :bar)))
            out = "{ :k => foo(:bar) }"
            compare(inp, out, processor)
          end

          it "wraps method call with block (iter) in parens" do
            iter = s(:iter, s(:call, nil, :foo), s(:args), s(:str, "bar"))
            inp = s(:hash, s(:lit, :k), iter)
            out = '{ :k => (foo { "bar" }) }'
            compare(inp, out, processor, false)
          end
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

    describe "#util_dthing" do
      let(:interpolation) {
        s('a"b',
          s(:evstr, s(:call, s(:lit, 1), :+, s(:lit, 1))),
          s(:str, 'c"d/e')
        )
      }

      context "dregx" do
        it "generates regex with interpolation" do
          out = '/a"b#{(1 + 1)}c"d\/e/'
          expect(out).to eval_to(/a"b2c"d\/e/)
          expect(processor.util_dthing(:dregx, interpolation)).to eq(out[1..-2])
        end

        it "generates regex with interpolation" do
          interpolation = s('[\/\"]', s(:evstr, s(:lit, 42)))
          out = '/[\/\"]#{42}/'
          expect(out).to eval_to(/[\/\"]42/)
          expect(processor.util_dthing(:dregx, interpolation)).to eq(out[1..-2])
        end
      end

      context "dstr" do
        it "generates string with interpolation" do
          out = '"a\"b#{(1 + 1)}c\"d/e"'
          expect(out).to eval_to('a"b2c"d/e')
          expect(processor.util_dthing(:dstr, interpolation)).to eq(out[1..-2])
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
