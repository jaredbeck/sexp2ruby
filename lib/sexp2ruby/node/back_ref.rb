module Sexp2Ruby
  module Node
    class BackRef < Base
      def to_s(exp)
        "$#{exp.shift}"
      end
    end
  end
end
