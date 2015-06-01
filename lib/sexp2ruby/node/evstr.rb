module Sexp2Ruby
  module Node
    class Evstr < Base
      def to_s(exp)
        exp.empty? ? '' : process(exp.shift)
      end
    end
  end
end
