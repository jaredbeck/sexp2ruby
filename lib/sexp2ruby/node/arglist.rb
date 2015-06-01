module Sexp2Ruby
  module Node
    class Arglist < Base
      def to_s(exp)
        code = []
        until exp.empty? do
          arg = exp.shift
          to_wrap = arg.first == :rescue
          arg_code = process arg
          code << (to_wrap ? "(#{arg_code})" : arg_code)
        end
        code.join ', '
      end
    end
  end
end
