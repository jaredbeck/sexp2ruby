module Sexp2Ruby
  module Node
    class Colon3 < Base
      def to_s(exp)
        "::#{exp.shift}"
      end
    end
  end
end
