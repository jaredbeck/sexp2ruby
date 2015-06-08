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
            iter = s(:iter, s(:call, nil, :foo), 0, s(:str, "bar"))
            inp = s(:hash, s(:lit, :k), iter)
            out = '{ :k => (foo { "bar" }) }'
            compare(inp, out, processor, false)
          end
        end
      end

      it "and_alias" do
        inn = s(:and, s(:true), s(:alias, s(:lit, :a), s(:lit, :b)))
        out = "true and (alias :a :b)"
        compare(inn, out, processor)
      end

      it "attr_reader_diff" do
        inn = s(:defn, :same, s(:args), s(:ivar, :@diff))
        out = "def same\n  @diff\nend"
        compare(inn, out, processor)
      end

      it "attr_reader_same" do
        inn = s(:defn, :same, s(:args), s(:ivar, :@same))
        out = "attr_reader :same"
        compare(inn, out, processor, false)
      end

      it "attr_reader_double" do
        inn = s(:defn, :same, s(:args), s(:ivar, :@same), s(:ivar, :@diff))
        out = "def same\n  @same\n  @diff\nend"
        compare(inn, out, processor)
      end

      it "attr_reader_same_name_diff_body" do
        inn = s(:defn, :same, s(:args), s(:not, s(:ivar, :@same)))
        out = "def same\n  (not @same)\nend"
        compare(inn, out, processor, false)
      end

      it "attr_writer_diff" do
        inn = s(:defn, :same=, s(:args, :o), s(:iasgn, :@diff, s(:lvar, :o)))
        out = "def same=(o)\n  @diff = o\nend"
        compare(inn, out, processor)
      end

      it "attr_writer_double" do
        inn = s(:defn, :same=, s(:args, :o),
          s(:iasgn, :@same, s(:lvar, :o)), s(:iasgn, :@diff, s(:lvar, :o)))
        out = "def same=(o)\n  @same = o\n  @diff = o\nend"
        compare(inn, out, processor)
      end

      it "attr_writer_same_name_diff_body" do
        inn = s(:defn, :same=, s(:args, :o), s(:iasgn, :@same, s(:lit, 42)))
        out = "def same=(o)\n  @same = 42\nend"
        compare(inn, out, processor)
      end

      it "attr_writer_same" do
        inn = s(:defn, :same=, s(:args, :o), s(:iasgn, :@same , s(:lvar, :o)))
        out = "attr_writer :same"
        compare(inn, out, processor, false)
      end

      it "dregx_slash" do
        inn = util_thingy(:dregx)
        out = '/a"b#{(1 + 1)}c"d\/e/'
        compare(inn, out, processor, false, /a"b2c"d\/e/)
      end

      it "dstr_quote" do
        inn = util_thingy(:dstr)
        out = '"a\"b#{(1 + 1)}c\"d/e"'
        compare(inn, out, processor, true, 'a"b2c"d/e')
      end

      it "dsym_quote" do
        inn = util_thingy(:dsym)
        out = ':"a\"b#{(1 + 1)}c\"d/e"'
        compare(inn, out, processor, true, :'a"b2c"d/e')
      end

      it "lit_regexp_slash" do
        inp = s(:lit, /blah\/blah/)
        compare(inp, '/blah\/blah/', processor, false, /blah\/blah/)
      end

      it "call_kwsplat" do
        inn = s(:call, nil, :test_splat, s(:hash, s(:kwsplat, s(:call, nil, :testing))))
        out = "test_splat(**testing)"
        compare(inn, out, processor)
      end

      it "call_arg_assoc_kwsplat" do
        inn = s(:call, nil, :f,
          s(:lit, 1),
          s(:hash, s(:lit, :kw), s(:lit, 2), s(:kwsplat, s(:lit, 3))))
        out = "f(1, :kw => 2, **3)"

        compare(inn, out, processor)
      end

      it "call_kwsplat_x" do
        inn = s(:call, nil, :a, s(:hash, s(:kwsplat, s(:lit, 1))))
        out = "a(**1)"

        compare(inn, out, processor)
      end

      it "defn_kwargs" do
        inn = s(:defn, :initialize,
          s(:args, :arg, s(:kwarg, :keyword, s(:nil)), :"**args"),
          s(:nil))
        out = "def initialize(arg, keyword: nil, **args)\n  # do nothing\nend"

        compare(inn, out, processor)
      end

      it "defn_kwargs2" do
        inn = s(:defn, :initialize,
          s(:args, :arg,
            s(:kwarg, :kw1, s(:nil)),
            s(:kwarg, :kw2, s(:nil)),
            :"**args"),
          s(:nil))
        out = "def initialize(arg, kw1: nil, kw2: nil, **args)\n  # do nothing\nend"

        compare(inn, out, processor)
      end

      it "call_self_index" do
        compare(s(:call, nil, :[], s(:lit, 42)), "self[42]", processor)
      end

      it "call_self_index_equals" do
        inp = s(:attrasgn, s(:self), :[]=, s(:lit, 42), s(:lit, 24))
        compare(inp, "self[42] = 24", processor)
      end

      it "call_self_index_equals_array" do
        inp = s(:attrasgn, s(:self), :[]=, s(:lit, 1), s(:lit, 2), s(:lit, 3))
        compare(inp, "self[1, 2] = 3", processor)
      end

      it "call_arglist_hash_first" do
        inn = s(:call, nil, :method,
          s(:hash, s(:lit, :a), s(:lit, 1)),
          s(:call, nil, :b))
        out = "method({ :a => 1 }, b)"

        compare(inn, out, processor)
      end

      it "call_arglist_hash_first_last" do
        inn = s(:call, nil, :method,
          s(:hash, s(:lit, :a), s(:lit, 1)),
          s(:call, nil, :b),
          s(:hash, s(:lit, :c), s(:lit, 1)))
        out = "method({ :a => 1 }, b, :c => 1)"

        compare(inn, out, processor)
      end

      it "call_arglist_hash_last" do
        inn = s(:call, nil, :method,
          s(:call, nil, :b),
          s(:hash, s(:lit, :a), s(:lit, 1)))
        out = "method(b, :a => 1)"

        compare(inn, out, processor)
      end

      it "call_arglist_if" do
        inn = s(:call,
          s(:call, nil, :a),
          :+,
          s(:if,
            s(:call, nil, :b),
            s(:call, nil, :c),
            s(:call, nil, :d)))

        out = "(a + (b ? (c) : (d)))"
        compare(inn, out, processor)
      end

      it "defn_kwsplat" do
        inn = s(:defn, :test, s(:args, :"**testing"), s(:nil))
        out = "def test(**testing)\n  # do nothing\nend"
        compare(inn, out, processor)
      end

      it "defn_rescue_return" do
        inn = s(:defn, :blah, s(:args),
          s(:rescue,
            s(:lasgn, :a, s(:lit, 1)),
            s(:resbody, s(:array), s(:return, s(:str, "a")))))
        out = "def blah\n  a = 1\nrescue\n  return \"a\"\nend"

        compare(inn, out, processor)
      end

      it "masgn_block_arg" do
        inn = s(:iter,
          s(:call,
            s(:nil),
            :x),
          s(:args, s(:masgn, :a, :b)),
          s(:dstr, "",
            s(:evstr, s(:lvar, :a)),
            s(:str, "="),
            s(:evstr, s(:lvar, :b))))
        out = 'nil.x { |(a, b)| "#{a}=#{b}" }'

        compare(inn, out, processor)
      end

      it "masgn_wtf" do
        inn = s(:block,
          s(:masgn,
            s(:array, s(:lasgn, :k), s(:lasgn, :v)),
            s(:splat,
              s(:call,
                s(:call, nil, :line),
                :split,
                s(:lit, /\=/), s(:lit, 2)))),
          s(:attrasgn,
            s(:self),
            :[]=,
            s(:lvar, :k),
            s(:call, s(:lvar, :v), :strip)))

        out = "k, v = *line.split(/\\=/, 2)\nself[k] = v.strip\n"

        compare(inn, out, processor)
      end

      it "masgn_splat_wtf" do
        inn = s(:masgn,
          s(:array, s(:lasgn, :k), s(:lasgn, :v)),
          s(:splat,
            s(:call,
              s(:call, nil, :line),
              :split,
              s(:lit, /\=/), s(:lit, 2))))
        out = 'k, v = *line.split(/\\=/, 2)'
        compare(inn, out, processor)
      end

      it "match3_asgn" do
        inn = s(:match3, s(:lit, //), s(:lasgn, :y, s(:call, nil, :x)))
        out = "(y = x) =~ //"
        # "y = x =~ //", which matches on x and assigns to y (not what sexp says).
        compare(inn, out, processor)
      end

      it "splat_call" do
        inn = s(:call, nil, :x,
          s(:splat,
            s(:call,
              s(:call, nil, :line),
              :split,
              s(:lit, /\=/), s(:lit, 2))))

        out = 'x(*line.split(/\=/, 2))'
        compare(inn, out, processor)
      end

      it "resbody_block" do
        inn = s(:rescue,
          s(:call, nil, :x1),
          s(:resbody,
            s(:array),
            s(:call, nil, :x2),
            s(:call, nil, :x3)))

        out = "begin\n  x1\nrescue\n  x2\n  x3\nend"
        compare(inn, out, processor)
      end

      it "resbody_short_with_begin_end" do
        # "begin; blah; rescue; []; end"
        inn = s(:rescue,
          s(:call, nil, :blah),
          s(:resbody, s(:array), s(:array)))
        out = "blah rescue []"
        compare(inn, out, processor)
      end

      it "resbody_short_with_begin_end_multiple" do
        # "begin; blah; rescue; []; end"
        inn = s(:rescue,
          s(:call, nil, :blah),
          s(:resbody, s(:array),
            s(:call, nil, :log),
            s(:call, nil, :raise)))
        out = "begin\n  blah\nrescue\n  log\n  raise\nend"
        compare(inn, out, processor)
      end

      it "resbody_short_with_defn_multiple" do
        inn = s(:defn,
          :foo,
          s(:args),
          s(:rescue,
            s(:lasgn, :a, s(:lit, 1)),
            s(:resbody,
              s(:array),
              s(:call, nil, :log),
              s(:call, nil, :raise))))
        out = "def foo\n  a = 1\nrescue\n  log\n  raise\nend"
        compare(inn, out, processor)
      end

      it "regexp_options" do
        inn = s(:match3,
          s(:dregx,
            "abc",
            s(:evstr, s(:call, nil, :x)),
            s(:str, "def"),
            4),
          s(:str, "a"))
        out = '"a" =~ /abc#{x}def/m'
        compare(inn, out, processor)
      end

      it "resbody_short_with_rescue_args" do
        inn = s(:rescue,
          s(:call, nil, :blah),
          s(:resbody, s(:array, s(:const, :A), s(:const, :B)), s(:array)))
        out = "begin\n  blah\nrescue A, B\n  []\nend"
        compare(inn, out, processor)
      end

      it "call_binary_call_with_hash_arg" do
        # if 42
        #   args << {:key => 24}
        # end

        inn = s(:if, s(:lit, 42),
          s(:call, s(:call, nil, :args),
            :<<,
            s(:hash, s(:lit, :key), s(:lit, 24))),
          nil)

        out = "(args << { :key => 24 }) if 42"

        compare(inn, out, processor)
      end

      it "binary_operators" do
        # (1 > 2)
        Node::Call::BINARY.each do |op|
          inn = s(:call, s(:lit, 1), op, s(:lit, 2))
          out = "(1 #{op} 2)"
          compare(inn, out, processor)
        end
      end

      it "call_empty_hash" do
        inn = s(:call, nil, :foo, s(:hash))
        out = "foo({})"
        compare(inn, out, processor)
      end

      it "if_empty" do
        inn = s(:if, s(:call, nil, :x), nil, nil)
        out = "if x then\n  # do nothing\nend"
        compare(inn, out, processor)
      end

      it "interpolation_and_escapes" do
        # log_entry = "  \e[#{message_color}m#{message}\e[0m   "
        inn = s(:lasgn, :log_entry,
          s(:dstr, "  \e[",
            s(:evstr, s(:call, nil, :message_color)),
            s(:str, "m"),
            s(:evstr, s(:call, nil, :message)),
            s(:str, "\e[0m   ")))
        out = "log_entry = \"  \e[#\{message_color}m#\{message}\e[0m   \""

        compare(inn, out, processor)
      end

      it "class_comments" do
        inn = s(:class, :Z, nil)
        inn.comments = "# x\n# y\n"
        out = "# x\n# y\nclass Z\nend"
        compare(inn, out, processor)
      end

      it "module_comments" do
        inn = s(:module, :Z)
        inn.comments = "# x\n# y\n"
        out = "# x\n# y\nmodule Z\nend"
        compare(inn, out, processor)
      end

      it "method_comments" do
        inn = s(:defn, :z, s(:args), s(:nil))
        inn.comments = "# x\n# y\n"
        out = "# x\n# y\ndef z\n  # do nothing\nend"
        compare(inn, out, processor)
      end

      it "basic_ensure" do
        inn = s(:ensure, s(:lit, 1), s(:lit, 2))
        out = "begin\n  1\nensure\n  2\nend"
        compare(inn, out, processor)
      end

      it "nested_ensure" do
        inn = s(:ensure, s(:lit, 1), s(:ensure, s(:lit, 2), s(:lit, 3)))
        out = "begin\n  1\nensure\n  begin\n    2\n  ensure\n    3\n  end\nend"
        compare(inn, out, processor)
      end

      it "nested_rescue" do
        inn = s(:ensure, s(:lit, 1), s(:rescue, s(:lit, 2), s(:resbody, s(:array), s(:lit, 3))))
        out = "begin\n  1\nensure\n  2 rescue 3\nend"
        compare(inn, out, processor)
      end

      it "nested_rescue_exception" do
        inn = s(:ensure, s(:lit, 1), s(:rescue, s(:lit, 2), s(:resbody, s(:array, s(:const, :Exception)), s(:lit, 3))))
        out = "begin\n  1\nensure\n  begin\n    2\n  rescue Exception\n    3\n  end\nend"
        compare(inn, out, processor)
      end

      it "nested_rescue_exception2" do
        inn = s(:ensure, s(:rescue, s(:lit, 2), s(:resbody, s(:array, s(:const, :Exception)), s(:lit, 3))), s(:lit, 1))
        out = "begin\n  2\nrescue Exception\n  3\nensure\n  1\nend"
        compare(inn, out, processor)
      end

      it "rescue_block" do
        inn = s(:rescue,
          s(:call, nil, :alpha),
          s(:resbody, s(:array),
            s(:call, nil, :beta),
            s(:call, nil, :gamma)))
        out = "begin\n  alpha\nrescue\n  beta\n  gamma\nend"
        compare(inn, out, processor)
      end

      it "array_adds_parens_around_rescue" do
        inn = s(:array,
          s(:call, nil, :a),
          s(:rescue, s(:call, nil, :b), s(:resbody, s(:array), s(:call, nil, :c))))
        out = "[a, (b rescue c)]"

        compare(inn, out, processor)
      end

      it "call_arglist_rescue" do
        inn = s(:call,
          nil,
          :method,
          s(:rescue,
            s(:call, nil, :a),
            s(:resbody, s(:array), s(:call, nil, :b))))
        out = "method((a rescue b))"
        compare(inn, out, processor)
      end

      it "unless_vs_if_not" do
        rb1 = "a unless b"
        rb2 = "a if (not b)"
        rb3 = "a if ! b"

        compare(Ruby18Parser.new.parse(rb1), rb1, processor)
        compare(Ruby19Parser.new.parse(rb1), rb1, processor)

        compare(Ruby18Parser.new.parse(rb2), rb1, processor)
        compare(Ruby19Parser.new.parse(rb2), rb2, processor)

        compare(Ruby18Parser.new.parse(rb3), rb1, processor)
        compare(Ruby19Parser.new.parse(rb3), rb2, processor)
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

    def util_thingy(type)
      s(type,
        'a"b',
        s(:evstr, s(:call, s(:lit, 1), :+, s(:lit, 1))),
        s(:str, 'c"d/e'))
    end
  end
end
