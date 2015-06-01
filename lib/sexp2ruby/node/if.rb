module Sexp2Ruby
  module Node
    class If < Base
      def to_s(exp)
        expand = ASSIGN_NODES.include? exp.first.first
        c = process exp.shift
        t = process exp.shift
        f = process exp.shift

        c = "(#{c.chomp})" if c =~ /\n/

        if t
          unless expand
            if f
              r = "#{c} ? (#{t}) : (#{f})"
              r = nil if r =~ /return/ # HACK - need contextual awareness or something
            else
              r = "#{t} if #{c}"
            end
            return r if r and (indent_lvl + r).size < LINE_LENGTH and r !~ /\n/
          end

          r = "if #{c} then\n#{indent(t)}\n"
          r << "else\n#{indent(f)}\n" if f
          r << "end"

          r
        elsif f
          unless expand
            r = "#{f} unless #{c}"
            return r if (indent_lvl + r).size < LINE_LENGTH and r !~ /\n/
          end
          "unless #{c} then\n#{indent(f)}\nend"
        else
          # empty if statement, just do it in case of side effects from condition
          "if #{c} then\n#{indent '# do nothing'}\nend"
        end
      end
    end
  end
end
