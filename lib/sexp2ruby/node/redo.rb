module Sexp2Ruby
  module Node
    class Redo < Base
      def to_s(exp)
        "redo"
      end
    end
  end
end
