module Sexp2Ruby
  module Node
    class Iasgn < Base
      def to_s(exp)
        lhs = exp.shift
        if exp.empty? # part of an masgn
          lhs.to_s
        else
          "#{lhs} = #{process exp.shift}"
        end
      end
    end
  end
end
