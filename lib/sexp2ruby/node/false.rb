module Sexp2Ruby
  module Node
    class False < Base
      def to_s(exp)
        "false"
      end
    end
  end
end
