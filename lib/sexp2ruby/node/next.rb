module Sexp2Ruby
  module Node
    class Next < Base
      def to_s(exp)
        val = exp.empty? ? nil : process(exp.shift)
        if val
          "next #{val}"
        else
          "next"
        end
      end
    end
  end
end
