module Sexp2Ruby
  module Node
    class Str < Base
      def to_s(exp)
        exp.shift.dump
      end
    end
  end
end
