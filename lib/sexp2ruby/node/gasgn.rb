module Sexp2Ruby
  module Node
    class Gasgn < Base
      def to_s(exp)
        process_iasgn(exp)
      end
    end
  end
end
