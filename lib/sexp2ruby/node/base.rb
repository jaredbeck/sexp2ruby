module Sexp2Ruby
  module Node

    # A node in the AST.
    class Base
      ASSIGN_NODES = Processor::ASSIGN_NODES
      LF = Processor::LF
      LINE_LENGTH = 78 # cutoff for one-liners

      attr_reader :processor
      delegate(
        :call_push,
        :call_pop,
        :cond_loop,
        :hash_syntax,
        :in_context,
        :indent,
        :indent_lvl,
        :finish,
        :parenthesize,
        :process,
        :process_arglist,
        :process_dregx,
        :process_iasgn,
        :ruby19_hash_key?,
        :util_dthing,
        :util_module_or_class,
        to: :processor
      )

      def initialize(processor)
        @processor = processor
      end
    end
  end
end
