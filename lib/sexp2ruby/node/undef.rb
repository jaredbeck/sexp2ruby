module Sexp2Ruby
  module Node
    class Undef < Base
      def to_s(exp)
        "undef #{process(exp.shift)}"
      end
    end
  end
end
