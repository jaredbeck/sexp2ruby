module Sexp2Ruby
  module Node
    # An `Iter`, AFAICT, is a `Call` with a block.
    #
    # Example:
    #
    # ```
    # # ruby
    # derp(foo) { |bar| herp }
    #
    # # sexp
    # s(
    #   :iter,
    #   s(:call, nil, :a, s(:call, nil, :b)),
    #   s(:args, :c),
    #   s(:call, nil, :d)
    # )
    # ```
    #
    class Iter < Base
      def to_s(exp)
        call_sexp = exp.shift

        # Process the `Call`. The Sexp is not consumed here (it is cloned)
        # because we will need to refer to it later, when determining which
        # block delimiters to use (brackets vs. do/end).
        iter = process(call_sexp.deep_clone)

        # The block arguments (as opposed to the `Call` arguments)
        args = exp.shift

        # The body of the block.
        body = exp.empty? ? nil : process(exp.shift)

        args = case args
        when 0 then
          ""
        else
          " |#{process(args)[1..-2]}|"
        end

        b, e = if iter == "END"
          [ "{", "}" ]
        else
          [ "do", "end" ]
        end

        iter.sub!(/\(\)$/, '')

        # REFACTOR: ugh
        result = []
        result << "#{iter} {"
        result << args
        result << (body ? " #{body.strip} " : "")
        result << "}"
        result = result.join

        # Can we squeeze the block onto the same line as the call?
        if same_line_bracket_block?(result, iter, call_sexp.deep_clone)
          return result
        end

        # We will not try to squeeze the block onto one line.
        result = []
        result << "#{iter} #{b}"
        result << args
        result << LF
        if body
          result << indent(body.strip)
          result << LF
        end
        result << e
        result.join
      end

      private

      # Given `iter` (a rendered `Call`), and `result`, should we try to
      # squeeze the body (`result`) onto the same line as `iter`? There are two
      # considerations.
      #
      # - Syntactic - did the `Call` parenthesize its arguments?
      # - Stylistic - would it exceed the line length
      #
      def same_line_bracket_block?(result, iter, call_sexp)
        call_sexp.shift # discard the sexp_type, as the processor would
        syntactic = !Call.new(processor).arguments?(call_sexp) || iter.end_with?(")")
        stylistic = result !~ /\n/ && result.size < LINE_LENGTH
        syntactic && stylistic
      end
    end
  end
end
