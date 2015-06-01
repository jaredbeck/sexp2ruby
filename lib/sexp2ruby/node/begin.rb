module Sexp2Ruby
  module Node

    # TODO: figure out how to do rescue and ensure ENTIRELY w/o begin
    class Begin < Base
      def to_s(exp)
        code = []
        code << "begin"
        until exp.empty?
          src = process(exp.shift)
          src = indent(src) unless src =~ /(^|\n)(rescue|ensure)/ # ensure no level 0 rescues
          code << src
        end
        code << "end"
        code.join(LF)
      end
    end
  end
end
