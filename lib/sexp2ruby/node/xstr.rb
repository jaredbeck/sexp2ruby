module Sexp2Ruby
  module Node
    class Xstr < Base
      def to_s(exp)
        "`#{process_str(exp)[1..-2]}`"
      end
    end
  end
end
