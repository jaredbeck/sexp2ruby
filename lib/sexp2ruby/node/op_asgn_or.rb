module Sexp2Ruby
  module Node
    class OpAsgnOr < Base

      # a ||= 1
      # [[:lvar, :a], [:lasgn, :a, [:lit, 1]]]
      def to_s(exp)
        exp.shift
        process(exp.shift).sub(/\=/, '||=')
      end
    end
  end
end
