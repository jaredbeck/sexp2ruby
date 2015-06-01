module Sexp2Ruby
  module Node
    class Match < Base
      def to_s(exp)
        "#{process(exp.shift)}"
      end
    end
  end
end
