require 'sexp_processor'

module Sexp2Ruby

  # Generate ruby code from a sexp.
  class Processor < SexpProcessor
    LF = "\n"

    # Nodes that represent assignment and probably need () around them.
    #
    # TODO: this should be replaced with full precedence support :/

    ASSIGN_NODES = [
                    :dasgn,
                    :flip2,
                    :flip3,
                    :lasgn,
                    :masgn,
                    :attrasgn,
                    :op_asgn1,
                    :op_asgn2,
                    :op_asgn_and,
                    :op_asgn_or,
                    :return,
                    :if, # HACK
                    :rescue,
                   ]

    HASH_SYNTAXES = [:ruby18, :ruby19]
    RUBY_19_HASH_KEY = /\A[a-z][_a-zA-Z0-9]+\Z/

    CONSTRUCTOR_OPTIONS = [
      :hash_syntax,
      :no_paren_methods
    ]

    NODES = [
      :alias,
      :and,
      :arglist,
      :args,
      :array,
      :attrasgn,
      :back_ref,
      :begin,
      :block,
      :block_pass,
      :break,
      :call,
      :case,
      :cdecl,
      :class,
      :colon2,
      :colon3,
      :const,
      :cvar,
      :cvasgn,
      :cvdecl,
      :defined,
      :defn,
      :defs,
      :dot2,
      :dot3,
      :dregx,
      :dregx_once,
      :dstr,
      :dsym,
      :dxstr,
      :ensure,
      :evstr,
      :false,
      :flip2,
      :flip3,
      :for,
      :gasgn,
      :gvar,
      :hash,
      :iasgn,
      :if,
      :iter,
      :ivar,
      :kwsplat,
      :lasgn,
      :lit,
      :lvar,
      :masgn,
      :match,
      :match2,
      :match3,
      :module,
      :next,
      :nil,
      :not,
      :nth_ref,
      :op_asgn1,
      :op_asgn2,
      :op_asgn_and,
      :op_asgn_or,
      :or,
      :postexe,
      :redo,
      :resbody,
      :rescue,
      :retry,
      :return,
      :sclass,
      :self,
      :splat,
      :str,
      :super,
      :svalue,
      :to_ary,
      :true,
      :undef,
      :until,
      :valias,
      :when,
      :while,
      :xstr,
      :yield,
      :zsuper
    ]

    attr_reader :hash_syntax, :indent_lvl, :no_paren_methods

    # Options:
    #
    # - `:hash_syntax` - either `:ruby18` or `:ruby19`.  Default is `:ruby19`.
    # - `:no_paren_methods` - an array of symbols, these methods
    #   will omit argument parentheses.  Default is `[]`.

    def initialize(option = {})
      super()
      check_option_keys(option)
      @hash_syntax = extract_option(HASH_SYNTAXES, option[:hash_syntax], :ruby19)
      @no_paren_methods = option[:no_paren_methods] || []
      @indent_lvl = "  "
      self.auto_shift_type = true
      self.strict = true
      self.expected = String
      @calls = []
    end

    # Process Methods
    # ---------------
    #
    # For each node that a SexpProcessor visits, it will call a
    # method `#process_X` where X is is the node's `sexp_type`.

    NODES.each do |p|
      define_method("process_#{p}") { |exp|
        "::Sexp2Ruby::Node::#{p.to_s.camelize}".
          constantize.
          new(self).
          to_s(exp)
      }
    end

    # State
    # -----

    def call_pop
      @calls.pop
    end

    def call_push(name)
      @calls.push(name)
    end

    # Rewriters
    # ---------

    def rewrite_attrasgn exp
      if context.first(2) == [:array, :masgn]
        exp[0] = :call
        exp[2] = exp[2].to_s.sub(/=$/, '').to_sym
      end

      exp
    end

    def rewrite_ensure exp
      exp = s(:begin, exp) unless context.first == :begin
      exp
    end

    def rewrite_resbody exp
      raise "no exception list in #{exp.inspect}" unless exp.size > 2 && exp[1]
      raise exp[1].inspect if exp[1][0] != :array
      # for now, do nothing, just check and freak if we see an errant structure
      exp
    end

    def rewrite_rescue exp
      complex = false
      complex ||= exp.size > 3
      complex ||= exp.resbody.block
      complex ||= exp.resbody.size > 3
      complex ||= exp.find_nodes(:resbody).any? { |n| n[1] != s(:array) }
      complex ||= exp.find_nodes(:resbody).any? { |n| n.last.nil? }
      complex ||= exp.find_nodes(:resbody).any? { |n| n[2] and n[2].node_type == :block }

      handled = context.first == :ensure

      exp = s(:begin, exp) if complex unless handled

      exp
    end

    def rewrite_svalue(exp)
      case exp.last.first
      when :array
        s(:svalue, *exp[1][1..-1])
      when :splat
        exp
      else
        raise "huh: #{exp.inspect}"
      end
    end

    # Utility Methods
    # ---------------

    def check_option_keys(option)
      diff = option.keys - CONSTRUCTOR_OPTIONS
      unless diff.empty?
        raise InvalidOption, "Invalid option(s): #{diff}"
      end
    end

    # Generate a post-or-pre conditional loop.
    def cond_loop(exp, name)
      cond = process(exp.shift)
      body = process(exp.shift)
      head_controlled = exp.shift

      body = indent(body).chomp if body

      code = []
      if head_controlled
        code << "#{name} #{cond} do"
        code << body if body
        code << "end"
      else
        code << "begin"
        code << body if body
        code << "end #{name} #{cond}"
      end
      code.join(LF)
    end

    # Escape something interpolated.
    def dthing_escape type, lit
      lit = lit.gsub(/\n/, '\n')
      case type
      when :dregx then
        lit.gsub(/(\A|[^\\])\//, '\1\/')
      when :dstr, :dsym then
        lit.gsub(/"/, '\"')
      when :dxstr then
        lit.gsub(/`/, '\`')
      else
        raise "unsupported type #{type.inspect}"
      end
    end

    # Check that `value` is in `array` of valid option values,
    # or raise InvalidOption.  If `value` is nil, return `default`.
    def extract_option(array, value, default)
      if value.nil?
        default
      elsif array.include?(value)
        value
      else
        raise InvalidOption, "Invalid option value: #{value}"
      end
    end

    # Process all the remaining stuff in +exp+ and return the results
    # sans-nils.
    def finish exp # REFACTOR: work this out of the rest of the processors
      body = []
      until exp.empty? do
        body << process(exp.shift)
      end
      body.compact
    end

    # Given `exp` representing the left side of a hash pair, return true
    # if it is compatible with the ruby 1.9 hash syntax.  For example,
    # the symbol `:foo` is compatible, but the literal `7` is not.  Note
    # that strings are not considered "compatible".  If we converted string
    # keys to symbol keys, we wouldn't be faithfully representing the input.
    def ruby19_hash_key?(exp)
      exp.sexp_type == :lit && exp.length == 2 && RUBY_19_HASH_KEY === exp[1].to_s
    end

    # Indent all lines of +s+ to the current indent level.
    def indent(s)
      s.to_s.split(/\n/).map{|line| @indent_lvl + line}.join(LF)
    end

    # Wrap appropriate expressions in matching parens.
    def parenthesize exp
      case self.context[1]
      when nil, :defn, :defs, :class, :sclass, :if, :iter, :resbody, :when, :while then
        exp
      else
        "(#{exp})"
      end
    end

    # Return a splatted symbol for +sym+.
    def splat(sym)
      :"*#{sym}"
    end

    # Generate something interpolated.
    def util_dthing(type, exp)
      s = []

      # first item in sexp is a string literal
      s << dthing_escape(type, exp.shift)

      until exp.empty?
        pt = exp.shift
        case pt
        when Sexp then
          case pt.first
          when :str then
            s << dthing_escape(type, pt.last)
          when :evstr then
            s << '#{' << process(pt) << '}' # do not use interpolation here
          else
            raise "unknown type: #{pt.inspect}"
          end
        else
          raise "unhandled value in d-thing: #{pt.inspect}"
        end
      end

      s.join
    end

    # Utility method to generate ether a module or class.
    def util_module_or_class(exp, is_class=false)
      result = []

      name = exp.shift
      name = process name if Sexp === name

      result << name

      if is_class
        superk = process(exp.shift)
        result << " < #{superk}" if superk
      end

      result << LF

      body = []
      begin
        code = process(exp.shift) unless exp.empty?
        body << code.chomp unless code.nil? or code.chomp.empty?
      end until exp.empty?

      body = body.empty? ? "" : indent(body.join("\n\n")) + LF
      result << body
      result << "end"

      result.join
    end
  end
end
