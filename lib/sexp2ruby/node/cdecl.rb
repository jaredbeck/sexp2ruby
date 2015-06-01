module Sexp2Ruby
  module Node
    class Cdecl < Base
      def to_s(exp)
        lhs = exp.shift
        lhs = process lhs if Sexp === lhs

        if exp.empty?
          lhs.to_s
        else
          rhs = process(exp.shift)
          "#{lhs} = #{rhs}"
        end
      end
    end
  end
end
