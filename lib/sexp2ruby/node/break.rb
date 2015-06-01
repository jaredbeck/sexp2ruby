module Sexp2Ruby
  module Node
    class Break < Base
      def to_s(exp)
        val = exp.empty? ? nil : process(exp.shift)
        if val
          "break #{val}"
        else
          "break"
        end
      end
    end
  end
end
