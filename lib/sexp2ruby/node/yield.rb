module Sexp2Ruby
  module Node
    class Yield < Base
      def to_s(exp)
        args = []
        until exp.empty? do
          args << process(exp.shift)
        end

        if args.empty?
          "yield"
        else
          "yield(#{args.join(', ')})"
        end
      end
    end
  end
end
