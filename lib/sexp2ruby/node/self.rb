module Sexp2Ruby
  module Node
    class Self < Base
      def to_s(exp)
        "self"
      end
    end
  end
end
