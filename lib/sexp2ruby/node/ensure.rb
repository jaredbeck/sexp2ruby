module Sexp2Ruby
  module Node
    class Ensure < Base
      def to_s(exp)
        body = process exp.shift
        ens  = exp.shift
        ens  = nil if ens == s(:nil)
        ens  = process(ens) || "# do nothing"
        ens = "begin\n#{ens}\nend\n" if ens =~ /(^|\n)rescue/

        body.sub!(/\n\s*end\z/, '')
        body = indent(body) unless body =~ /(^|\n)rescue/

        "#{body}\nensure\n#{indent ens}"
      end
    end
  end
end
