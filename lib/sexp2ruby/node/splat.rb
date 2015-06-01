module Sexp2Ruby
  module Node
    class Splat < Base
      def to_s(exp)
        if exp.empty?
          "*"
        else
          "*#{process(exp.shift)}"
        end
      end
    end
  end
end
