module Sexp2Ruby
  module Node
    # A method call.
    #
    # Examples:
    #
    # ```
    # a
    # s(:call, nil, :a)
    #
    # A.b
    # s(:call, s(:const, :A), :b)
    #
    # a(b)
    # s(:call, nil, :a, s(:call, nil, :b))
    #
    # a(b, c: d, &e)
    # s(
    #   :call,
    #   nil,
    #   :a,
    #   s(:call, nil, :b),
    #   s(:hash, s(:lit, :c), s(:call, nil, :d)),
    #   s(:block_pass, s(:call, nil, :e))
    # )
    #
    # a = :a; a.b
    # s(
    #   :block,
    #   s(:lasgn, :a, s(:lit, :a)),
    #   s(:call, s(:lvar, :a), :b)
    # )
    # ```
    class Call < Base
      # binary operation messages
      BINARY = [:<=>, :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :%, :<<, :>>, :**, :'!=']

      def arguments?(exp)
        exp.length > 2 # 1. receiver, 2. method name, 3+ arguments
      end

      def to_s(exp)
        receiver_node_type = exp.first.nil? ? nil : exp.first.first
        receiver = process exp.shift
        receiver = "(#{receiver})" if ASSIGN_NODES.include? receiver_node_type

        name = exp.shift
        args = []

        # this allows us to do both old and new sexp forms:
        exp.push(*exp.pop[1..-1]) if exp.size == 1 && exp.first.first == :arglist

        call_push(name)

        in_context :arglist do
          until exp.empty? do
            arg_type = exp.first.sexp_type
            is_empty_hash = (exp.first == s(:hash))
            arg = process exp.shift

            next if arg.empty?

            strip_hash = (arg_type == :hash and
              not BINARY.include? name and
              not is_empty_hash and
              (exp.empty? or exp.first.sexp_type == :splat))
            wrap_arg = ASSIGN_NODES.include? arg_type

            arg = arg[2..-3] if strip_hash
            arg = "(#{arg})" if wrap_arg

            args << arg
          end
        end

        case name
        when *BINARY then
          "(#{receiver} #{name} #{args.join(', ')})"
        when :[] then
          receiver ||= "self"
          "#{receiver}[#{args.join(', ')}]"
        when :[]= then
          receiver ||= "self"
          rhs = args.pop
          "#{receiver}[#{args.join(', ')}] = #{rhs}"
        when :"!" then
          "(not #{receiver})"
        when :"-@" then
          "-#{receiver}"
        when :"+@" then
          "+#{receiver}"
        else
          args = arguments(args, name)
          receiver = "#{receiver}." if receiver
          "#{receiver}#{name}#{args}"
        end
      ensure
        call_pop
      end

      private

      def arguments(args, name)
        if args.empty?
          ""
        else
          fmt = argument_parentheses?(name) ? "(%s)" : " %s"
          str = "#{args.join(', ')}"
          fmt % str
        end
      end

      def argument_parentheses?(name)
        !no_paren_methods.include?(name.to_sym)
      end
    end
  end
end
