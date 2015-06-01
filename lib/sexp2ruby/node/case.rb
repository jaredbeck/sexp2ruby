module Sexp2Ruby
  module Node
    class Case < Base
      def to_s(exp)
        result = []
        expr = process exp.shift
        if expr
          result << "case #{expr}"
        else
          result << "case"
        end
        until exp.empty?
          pt = exp.shift
          if pt and pt.first == :when
            result << "#{process(pt)}"
          else
            code = indent(process(pt))
            code = indent("# do nothing") if code =~ /^\s*$/
            result << "else\n#{code}"
          end
        end
        result << "end"
        result.join(LF)
      end
    end
  end
end
