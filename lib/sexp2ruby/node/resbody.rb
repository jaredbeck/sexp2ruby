module Sexp2Ruby
  module Node
    class Resbody < Base
      def to_s(exp)
        args = exp.shift
        body = finish(exp)
        body << "# do nothing" if body.empty?

        name =   args.lasgn true
        name ||= args.iasgn true
        args = process(args)[1..-2]
        args = " #{args}" unless args.empty?
        args += " => #{name[1]}" if name

        "rescue#{args}\n#{indent body.join(LF)}"
      end
    end
  end
end
