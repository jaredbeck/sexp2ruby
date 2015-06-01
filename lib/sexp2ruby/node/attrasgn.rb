module Sexp2Ruby
  module Node
    class Attrasgn < Base
      def to_s(exp)
        receiver = process exp.shift
        name = exp.shift
        rhs  = exp.pop
        args = s(:array, *exp)
        exp.clear

        case name
        when :[]= then
          args = process args
          "#{receiver}#{args} = #{process rhs}"
        else
          raise "dunno what to do: #{args.inspect}" unless args.size == 1 # s(:array)
          name = name.to_s.sub(/=$/, '')
          if rhs && rhs != s(:arglist)
            "#{receiver}.#{name} = #{process(rhs)}"
          else
            raise "dunno what to do: #{rhs.inspect}"
          end
        end
      end
    end
  end
end
