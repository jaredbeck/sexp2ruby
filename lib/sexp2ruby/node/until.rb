module Sexp2Ruby
  module Node
    class Until < Base
      def to_s(exp)
        cond_loop(exp, 'until')
      end
    end
  end
end
