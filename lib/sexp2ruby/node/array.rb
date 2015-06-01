module Sexp2Ruby
  module Node
    class Array < Base
      def to_s(exp)
        "[#{process_arglist(exp)}]"
      end
    end
  end
end
