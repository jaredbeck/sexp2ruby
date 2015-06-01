module Sexp2Ruby
  module Node
    class Iter < Base
      def to_s(exp)
        iter = process exp.shift
        args = exp.shift
        body = exp.empty? ? nil : process(exp.shift)

        args = case args
        when 0 then
          " ||"
        else
          a = process(args)[1..-2]
          a = " |#{a}|" unless a.empty?
          a
        end

        b, e = if iter == "END"
          [ "{", "}" ]
        else
          [ "do", "end" ]
        end

        iter.sub!(/\(\)$/, '')

        # REFACTOR: ugh
        result = []
        result << "#{iter} {"
        result << args
        if body
          result << " #{body.strip} "
        else
          result << ' '
        end
        result << "}"
        result = result.join
        return result if result !~ /\n/ and result.size < LINE_LENGTH

        result = []
        result << "#{iter} #{b}"
        result << args
        result << LF
        if body
          result << indent(body.strip)
          result << LF
        end
        result << e
        result.join
      end
    end
  end
end
