module Sexp2Ruby
  module Node
    class Hash < Base

      # Some sexp types are OK without parens when appearing as hash values.
      # This list can include `:call`s because they're always printed with parens
      # around their arguments. For example:
      #
      #     { :foo => (bar("baz")) } # The outer parens are unnecessary
      #     { :foo => bar("baz") }   # This is the normal code style
      #
      HASH_VAL_NO_PAREN = [
        :call,
        :false,
        :hash,
        :lit,
        :lvar,
        :nil,
        :str,
        :true
      ]

      def to_s(exp)
        result = []

        until exp.empty?
          s = exp.shift
          t = s.sexp_type
          ruby19_key = ruby19_hash_key?(s)
          lhs = process s

          case t
          when :kwsplat then
            result << lhs
          else
            rhs = exp.shift
            t = rhs.first
            rhs = process rhs
            rhs = "(#{rhs})" unless HASH_VAL_NO_PAREN.include? t

            if hash_syntax == :ruby19 && ruby19_key
              lhs.gsub!(/\A:/, "")
              result << "#{lhs}: #{rhs}"
            else
              result << "#{lhs} => #{rhs}"
            end
          end
        end

        result.empty? ? "{}" : "{ #{result.join(', ')} }"
      end
    end
  end
end
