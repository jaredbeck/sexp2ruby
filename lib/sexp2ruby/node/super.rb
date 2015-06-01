module Sexp2Ruby
  module Node
    class Super < Base
      def to_s(exp)
        args = finish exp
        "super(#{args.join(', ')})"
      end
    end
  end
end
