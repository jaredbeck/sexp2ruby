module Sexp2Ruby
  module Node
    class Cvdecl < Base
      def to_s(exp)
        "#{exp.shift} = #{process(exp.shift)}"
      end
    end
  end
end
