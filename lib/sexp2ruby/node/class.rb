module Sexp2Ruby
  module Node
    class Class < Base
      def to_s(exp)
        "#{exp.comments}class #{util_module_or_class(exp, true)}"
      end
    end
  end
end
