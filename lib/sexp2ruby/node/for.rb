module Sexp2Ruby
  module Node
    class For < Base
      def to_s(exp)
        recv = process exp.shift
        iter = process exp.shift
        body = exp.empty? ? nil : process(exp.shift)

        result = ["for #{iter} in #{recv} do"]
        result << indent(body ? body : "# do nothing")
        result << "end"

        result.join(LF)
      end
    end
  end
end
