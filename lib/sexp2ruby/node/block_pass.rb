module Sexp2Ruby
  module Node
    class BlockPass < Base
      def to_s(exp)
        raise "huh?: #{exp.inspect}" if exp.size > 1
        "&#{process exp.shift}"
      end
    end
  end
end
