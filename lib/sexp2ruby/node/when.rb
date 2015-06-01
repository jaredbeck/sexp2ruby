module Sexp2Ruby
  module Node
    class When < Base
      def to_s(exp)
        src = []

        if self.context[1] == :array # ugh. matz! why not an argscat?!?
          val = process(exp.shift)
          exp.shift # empty body
          return "*#{val}"
        end

        until exp.empty?
          cond = process(exp.shift).to_s[1..-2]
          code = indent(finish(exp).join(LF))
          code = indent "# do nothing" if code =~ /\A\s*\Z/
          src << "when #{cond} then\n#{code.chomp}"
        end

        src.join(LF)
      end
    end
  end
end
