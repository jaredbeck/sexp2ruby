module Sexp2Ruby
  module Node
    class Match2 < Base
      def to_s(exp)
        lhs = process(exp.shift)
        rhs = process(exp.shift)
        "#{lhs} =~ #{rhs}"
      end
    end
  end
end
