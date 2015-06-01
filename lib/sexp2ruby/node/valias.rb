module Sexp2Ruby
  module Node
    class Valias < Base
      def to_s(exp)
        "alias #{exp.shift} #{exp.shift}"
      end
    end
  end
end
