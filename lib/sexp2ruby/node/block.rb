module Sexp2Ruby
  module Node
    class Block < Base
      def to_s(exp)
        result = []

        exp << nil if exp.empty?
        until exp.empty? do
          code = exp.shift
          if code.nil? or code.first == :nil
            result << "# do nothing\n"
          else
            result << process(code)
          end
        end

        result = parenthesize result.join LF
        result += LF unless result.start_with? "("

        result
      end
    end
  end
end
