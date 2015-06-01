module Sexp2Ruby
  module Node
    class Masgn < Base

      # s(:masgn, s(:array, s(:lasgn, :var), ...), s(:to_ary, <val>, ...))
      # s(:iter, <call>, s(:args, s(:masgn, :a, :b)), <body>)
      def to_s(exp)
        case exp.first
        when Sexp then
          lhs = exp.shift
          rhs = exp.empty? ? nil : exp.shift

          case lhs.first
          when :array then
            lhs.shift # node type
            lhs = lhs.map do |l|
              case l.first
              when :masgn then
                "(#{process(l)})"
              else
                process(l)
              end
            end
          else
            raise "no clue: #{lhs.inspect}"
          end

          if rhs.nil?
            return lhs.join(", ")
          else
            t = rhs.first
            rhs = process rhs
            rhs = rhs[1..-2] if t == :array # FIX: bad? I dunno
            return "#{lhs.join(", ")} = #{rhs}"
          end
        when Symbol then # block arg list w/ masgn
          result = exp.join ", "
          exp.clear
          "(#{result})"
        else
          raise "unknown masgn: #{exp.inspect}"
        end
      end
    end
  end
end
