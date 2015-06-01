module Sexp2Ruby
  module Node
    class Defn < Base
      def to_s(exp)
        type1 = exp[1].first
        type2 = exp[2].first rescue nil
        expect = [:ivar, :iasgn, :attrset]

        # s(name, args, ivar|iasgn|attrset)
        if exp.size == 3 and type1 == :args and expect.include? type2
          name = exp.first # don't shift in case we pass through
          case type2
          when :ivar then
            ivar_name = exp.ivar.last

            meth_name = ivar_name.to_s[1..-1].to_sym
            expected = s(meth_name, s(:args), s(:ivar, ivar_name))

            if exp == expected
              exp.clear
              return "attr_reader #{name.inspect}"
            end
          when :attrset then
            # TODO: deprecate? this is a PT relic
            exp.clear
            return "attr_writer :#{name.to_s[0..-2]}"
          when :iasgn then
            ivar_name = exp.iasgn[1]
            meth_name = "#{ivar_name.to_s[1..-1]}=".to_sym
            arg_name = exp.args.last
            expected = s(meth_name, s(:args, arg_name),
              s(:iasgn, ivar_name, s(:lvar, arg_name)))

            if exp == expected
              exp.clear
              return "attr_writer :#{name.to_s[0..-2]}"
            end
          else
            raise "Unknown defn type: #{exp.inspect}"
          end
        end

        comm = exp.comments
        name = exp.shift
        args = process exp.shift
        args = "" if args == "()"

        exp.shift if exp == s(s(:nil)) # empty it out of a default nil expression

        # REFACTOR: use process_block but get it happier wrt parenthesize
        body = []
        until exp.empty? do
          body << process(exp.shift)
        end

        body << "# do nothing" if body.empty?
        body = body.join(LF)
        body = body.lines.to_a[1..-2].join(LF) if
          body =~ /^\Abegin/ && body =~ /^end\z/
        body = indent(body) unless body =~ /(^|\n)rescue/

        "#{comm}def #{name}#{args}\n#{body}\nend".gsub(/\n\s*\n+/, LF)
      end
    end
  end
end
