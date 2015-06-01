module Sexp2Ruby
  module Node
    class Return < Base
      def to_s(exp)
        if exp.empty?
          "return"
        else
          "return #{process exp.shift}"
        end
      end
    end
  end
end
