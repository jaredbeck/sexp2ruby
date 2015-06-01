module Sexp2Ruby
  module Node
    class Args < Base
      def to_s(exp)
        args = []

        until exp.empty? do
          arg = exp.shift
          case arg
          when Symbol then
            args << arg
          when Sexp then
            case arg.first
            when :lasgn then
              args << process(arg)
            when :masgn then
              args << process(arg)
            when :kwarg then
              _, k, v = arg
              args << "#{k}: #{process v}"
            else
              raise "unknown arg type #{arg.first.inspect}"
            end
          else
            raise "unknown arg type #{arg.inspect}"
          end
        end

        "(#{args.join ', '})"
      end
    end
  end
end
