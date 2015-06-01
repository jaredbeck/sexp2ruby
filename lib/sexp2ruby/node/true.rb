module Sexp2Ruby
  module Node
    class True < Base
      def to_s(exp)
        "true"
      end
    end
  end
end
