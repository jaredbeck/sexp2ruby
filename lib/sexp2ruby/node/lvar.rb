module Sexp2Ruby
  module Node
    class Lvar < Base
      def to_s(exp)
        exp.shift.to_s
      end
    end
  end
end
