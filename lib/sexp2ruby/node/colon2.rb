module Sexp2Ruby
  module Node
    class Colon2 < Base
      def to_s(exp)
        "#{process(exp.shift)}::#{exp.shift}"
      end
    end
  end
end
