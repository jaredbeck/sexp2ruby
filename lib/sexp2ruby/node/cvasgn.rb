module Sexp2Ruby
  module Node
    class Cvasgn < Base
      def to_s(exp)
        "#{exp.shift} = #{process(exp.shift)}"
      end
    end
  end
end
