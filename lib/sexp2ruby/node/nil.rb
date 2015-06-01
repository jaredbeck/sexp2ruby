module Sexp2Ruby
  module Node
    class Nil < Base
      def to_s(exp)
        "nil"
      end
    end
  end
end
