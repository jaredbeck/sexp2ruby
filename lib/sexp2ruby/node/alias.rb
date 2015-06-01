module Sexp2Ruby
  module Node
    class Alias < Base
      def to_s(exp)
        parenthesize "alias #{process(exp.shift)} #{process(exp.shift)}"
      end
    end
  end
end
