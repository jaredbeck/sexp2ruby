module Sexp2Ruby
  module Node
    class Lit < Base
      def to_s(exp)
        obj = exp.shift
        case obj
        when Range then
          "(#{obj.inspect})"
        else
          obj.inspect
        end
      end
    end
  end
end
