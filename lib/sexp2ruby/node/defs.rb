module Sexp2Ruby
  module Node
    class Defs < Base
      def to_s(exp)
        lhs  = exp.shift
        var = [:self, :cvar, :dvar, :ivar, :gvar, :lvar].include? lhs.first
        name = exp.shift

        lhs = process(lhs)
        lhs = "(#{lhs})" unless var

        exp.unshift "#{lhs}.#{name}"
        process_defn(exp)
      end
    end
  end
end
