module Sexp2Ruby
  module Node
    class Module < Base
      def to_s(exp)
        "#{exp.comments}module #{util_module_or_class(exp)}"
      end
    end
  end
end
