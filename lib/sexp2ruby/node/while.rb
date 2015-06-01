module Sexp2Ruby
  module Node
    class While < Base
      def to_s(exp)
        cond_loop(exp, 'while')
      end
    end
  end
end
