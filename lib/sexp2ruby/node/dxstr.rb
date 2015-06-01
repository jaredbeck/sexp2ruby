module Sexp2Ruby
  module Node
    class Dxstr < Base
      def to_s(exp)
        "`#{util_dthing(:dxstr, exp)}`"
      end
    end
  end
end
