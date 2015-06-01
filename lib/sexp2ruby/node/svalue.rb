module Sexp2Ruby
  module Node
    class Svalue < Base
      def to_s(exp)
        code = []
        until exp.empty? do
          code << process(exp.shift)
        end
        code.join(", ")
      end
    end
  end
end
