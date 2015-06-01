module Sexp2Ruby
  module Node
    class Lasgn < Base
      def to_s(exp)
        s = "#{exp.shift}"
        s += " = #{process exp.shift}" unless exp.empty?
        s
      end
    end
  end
end
