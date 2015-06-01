module Sexp2Ruby
  module Node
    class DregxOnce < Base
      def to_s(exp)
        process_dregx(exp) + "o"
      end
    end
  end
end
