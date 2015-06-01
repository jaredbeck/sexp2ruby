module Sexp2Ruby
  module Node
    class Defined < Base
      def to_s(exp)
        "defined? #{process(exp.shift)}"
      end
    end
  end
end
