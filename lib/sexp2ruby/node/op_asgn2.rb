module Sexp2Ruby
  module Node
    class OpAsgn2 < Base

      # [[:lvar, :c], :var=, :"||", [:lit, 20]]
      def to_s(exp)
        lhs = process(exp.shift)
        index = exp.shift.to_s[0..-2]
        msg = exp.shift

        rhs = process(exp.shift)

        "#{lhs}.#{index} #{msg}= #{rhs}"
      end
    end
  end
end
