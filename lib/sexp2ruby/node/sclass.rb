module Sexp2Ruby
  module Node
    class Sclass < Base
      def to_s(exp)
        "class << #{process(exp.shift)}\n#{indent(process_block(exp))}\nend"
      end
    end
  end
end
