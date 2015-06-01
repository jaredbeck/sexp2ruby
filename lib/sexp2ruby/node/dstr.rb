module Sexp2Ruby
  module Node
    class Dstr < Base
      def to_s(exp)
        "\"#{util_dthing(:dstr, exp)}\""
      end
    end
  end
end
