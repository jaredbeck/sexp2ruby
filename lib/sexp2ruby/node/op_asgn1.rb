module Sexp2Ruby
  module Node
    class OpAsgn1 < Base

      # [[:lvar, :b], [:arglist, [:lit, 1]], :"||", [:lit, 10]]
      def to_s(exp)
        lhs = process(exp.shift)
        index = process(exp.shift)
        msg = exp.shift
        rhs = process(exp.shift)

        "#{lhs}[#{index}] #{msg}= #{rhs}"
      end
    end
  end
end
