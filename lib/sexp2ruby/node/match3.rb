module Sexp2Ruby
  module Node
    class Match3 < Base
      def to_s(exp)
        rhs = process(exp.shift)
        left_type = exp.first.sexp_type
        lhs = process(exp.shift)

        if ASSIGN_NODES.include? left_type
          "(#{lhs}) =~ #{rhs}"
        else
          "#{lhs} =~ #{rhs}"
        end
      end
    end
  end
end
