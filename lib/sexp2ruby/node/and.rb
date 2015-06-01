module Sexp2Ruby
  module Node
    class And < Base
      def to_s(exp)
        parenthesize "#{process exp.shift} and #{process exp.shift}"
      end
    end
  end
end
