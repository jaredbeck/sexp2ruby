module Sexp2Ruby
  module Node
    class Dsym < Base
      def to_s(exp)
        ":\"#{util_dthing(:dsym, exp)}\""
      end
    end
  end
end
