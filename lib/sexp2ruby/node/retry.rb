module Sexp2Ruby
  module Node
    class Retry < Base
      def to_s(exp)
        "retry"
      end
    end
  end
end
