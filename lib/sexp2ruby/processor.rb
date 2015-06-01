require 'sexp_processor'

module Sexp2Ruby

  # Generate ruby code from a sexp.
  class Processor < SexpProcessor
    LF = "\n"

    # cutoff for one-liners
    LINE_LENGTH = 78

    # binary operation messages
    BINARY = [:<=>, :==, :<, :>, :<=, :>=, :-, :+, :*, :/, :%, :<<, :>>, :**, :'!=']

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

    # Some sexp types are OK without parens when appearing as hash values.
    # This list can include `:call`s because they're always printed with parens
    # around their arguments. For example:
    #
    #     { :foo => (bar("baz")) } # The outer parens are unnecessary
    #     { :foo => bar("baz") }   # This is the normal code style

    HASH_VAL_NO_PAREN = [
      :call,
      :false,
      :lit,
      :lvar,
      :nil,
      :str,
      :true
    ]

    HASH_SYNTAXES = [:ruby18, :ruby19]
    RUBY_19_HASH_KEY = /\A[a-z][_a-zA-Z0-9]+\Z/

    CONSTRUCTOR_OPTIONS = [:hash_syntax]

    attr_reader :hash_syntax

    # Options:
    #
    # - `:hash_syntax` - either `:ruby18` or `:ruby19`

    def initialize(option = {})
      super()
      check_option_keys(option)
      @hash_syntax = extract_option(HASH_SYNTAXES, option[:hash_syntax], :ruby18)
      @indent = "  "
      self.auto_shift_type = true
      self.strict = true
      self.expected = String
      @calls = []
    end

    # Processors
    # ----------

    def process_alias(exp)
      parenthesize "alias #{process(exp.shift)} #{process(exp.shift)}"
    end

    def process_and(exp)
      parenthesize "#{process exp.shift} and #{process exp.shift}"
    end

    def process_arglist(exp) # custom made node
      code = []
      until exp.empty? do
        arg = exp.shift
        to_wrap = arg.first == :rescue
        arg_code = process arg
        code << (to_wrap ? "(#{arg_code})" : arg_code)
      end
      code.join ', '
    end

    def process_args(exp)
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

    def process_array(exp)
      "[#{process_arglist(exp)}]"
    end

    def process_attrasgn(exp)
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

    def process_back_ref(exp)
      "$#{exp.shift}"
    end

    # TODO: figure out how to do rescue and ensure ENTIRELY w/o begin
    def process_begin(exp)
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

    def process_block(exp)
      result = []

      exp << nil if exp.empty?
      until exp.empty? do
        code = exp.shift
        if code.nil? or code.first == :nil
          result << "# do nothing\n"
        else
          result << process(code)
        end
      end

      result = parenthesize result.join LF
      result += LF unless result.start_with? "("

      result
    end

    def process_block_pass exp
      raise "huh?: #{exp.inspect}" if exp.size > 1

      "&#{process exp.shift}"
    end

    def process_break(exp)
      val = exp.empty? ? nil : process(exp.shift)
      if val
        "break #{val}"
      else
        "break"
      end
    end

    def process_call(exp)
      receiver_node_type = exp.first.nil? ? nil : exp.first.first
      receiver = process exp.shift
      receiver = "(#{receiver})" if ASSIGN_NODES.include? receiver_node_type

      name = exp.shift
      args = []

      # this allows us to do both old and new sexp forms:
      exp.push(*exp.pop[1..-1]) if exp.size == 1 && exp.first.first == :arglist

      @calls.push name

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
        args     = nil                    if args.empty?
        args     = "(#{args.join(', ')})" if args
        receiver = "#{receiver}."         if receiver

        "#{receiver}#{name}#{args}"
      end
    ensure
      @calls.pop
    end

    def process_case(exp)
      result = []
      expr = process exp.shift
      if expr
        result << "case #{expr}"
      else
        result << "case"
      end
      until exp.empty?
        pt = exp.shift
        if pt and pt.first == :when
          result << "#{process(pt)}"
        else
          code = indent(process(pt))
          code = indent("# do nothing") if code =~ /^\s*$/
          result << "else\n#{code}"
        end
      end
      result << "end"
      result.join(LF)
    end

    def process_cdecl(exp)
      lhs = exp.shift
      lhs = process lhs if Sexp === lhs

      if exp.empty?
        lhs.to_s
      else
        rhs = process(exp.shift)
        "#{lhs} = #{rhs}"
      end
    end

    def process_class(exp)
      "#{exp.comments}class #{util_module_or_class(exp, true)}"
    end

    def process_colon2(exp)
      "#{process(exp.shift)}::#{exp.shift}"
    end

    def process_colon3(exp)
      "::#{exp.shift}"
    end

    def process_const(exp)
      exp.shift.to_s
    end

    def process_cvar(exp)
      "#{exp.shift}"
    end

    def process_cvasgn(exp)
      "#{exp.shift} = #{process(exp.shift)}"
    end

    def process_cvdecl(exp)
      "#{exp.shift} = #{process(exp.shift)}"
    end

    def process_defined(exp)
      "defined? #{process(exp.shift)}"
    end

    def process_defn(exp)
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

    def process_defs(exp)
      lhs  = exp.shift
      var = [:self, :cvar, :dvar, :ivar, :gvar, :lvar].include? lhs.first
      name = exp.shift

      lhs = process(lhs)
      lhs = "(#{lhs})" unless var

      exp.unshift "#{lhs}.#{name}"
      process_defn(exp)
    end

    def process_dot2(exp)
      "(#{process exp.shift}..#{process exp.shift})"
    end

    def process_dot3(exp)
      "(#{process exp.shift}...#{process exp.shift})"
    end

    def process_dregx(exp)
      options = re_opt exp.pop if Fixnum === exp.last
      "/" << util_dthing(:dregx, exp) << "/#{options}"
    end

    def process_dregx_once(exp)
      process_dregx(exp) + "o"
    end

    def process_dstr(exp)
      "\"#{util_dthing(:dstr, exp)}\""
    end

    def process_dsym(exp)
      ":\"#{util_dthing(:dsym, exp)}\""
    end

    def process_dxstr(exp)
      "`#{util_dthing(:dxstr, exp)}`"
    end

    def process_ensure(exp)
      body = process exp.shift
      ens  = exp.shift
      ens  = nil if ens == s(:nil)
      ens  = process(ens) || "# do nothing"
      ens = "begin\n#{ens}\nend\n" if ens =~ /(^|\n)rescue/

      body.sub!(/\n\s*end\z/, '')
      body = indent(body) unless body =~ /(^|\n)rescue/

      "#{body}\nensure\n#{indent ens}"
    end

    def process_evstr(exp)
      exp.empty? ? '' : process(exp.shift)
    end

    def process_false(exp)
      "false"
    end

    def process_flip2(exp)
      "#{process(exp.shift)}..#{process(exp.shift)}"
    end

    def process_flip3(exp)
      "#{process(exp.shift)}...#{process(exp.shift)}"
    end

    def process_for(exp)
      recv = process exp.shift
      iter = process exp.shift
      body = exp.empty? ? nil : process(exp.shift)

      result = ["for #{iter} in #{recv} do"]
      result << indent(body ? body : "# do nothing")
      result << "end"

      result.join(LF)
    end

    def process_gasgn(exp)
      process_iasgn(exp)
    end

    def process_gvar(exp)
      exp.shift.to_s
    end

    def process_hash(exp)
      result = []

      until exp.empty?
        s = exp.shift
        t = s.sexp_type
        ruby19_key = ruby19_hash_key?(s)
        lhs = process s

        case t
        when :kwsplat then
          result << lhs
        else
          rhs = exp.shift
          t = rhs.first
          rhs = process rhs
          rhs = "(#{rhs})" unless HASH_VAL_NO_PAREN.include? t

          if hash_syntax == :ruby19 && ruby19_key
            lhs.gsub!(/\A:/, "")
            result << "#{lhs}: #{rhs}"
          else
            result << "#{lhs} => #{rhs}"
          end
        end
      end

      result.empty? ? "{}" : "{ #{result.join(', ')} }"
    end

    def process_iasgn(exp)
      lhs = exp.shift
      if exp.empty? # part of an masgn
        lhs.to_s
      else
        "#{lhs} = #{process exp.shift}"
      end
    end

    def process_if(exp)
      expand = ASSIGN_NODES.include? exp.first.first
      c = process exp.shift
      t = process exp.shift
      f = process exp.shift

      c = "(#{c.chomp})" if c =~ /\n/

      if t
        unless expand
          if f
            r = "#{c} ? (#{t}) : (#{f})"
            r = nil if r =~ /return/ # HACK - need contextual awareness or something
          else
            r = "#{t} if #{c}"
          end
          return r if r and (@indent+r).size < LINE_LENGTH and r !~ /\n/
        end

        r = "if #{c} then\n#{indent(t)}\n"
        r << "else\n#{indent(f)}\n" if f
        r << "end"

        r
      elsif f
        unless expand
          r = "#{f} unless #{c}"
          return r if (@indent+r).size < LINE_LENGTH and r !~ /\n/
        end
        "unless #{c} then\n#{indent(f)}\nend"
      else
        # empty if statement, just do it in case of side effects from condition
        "if #{c} then\n#{indent '# do nothing'}\nend"
      end
    end

    def process_iter(exp)
      iter = process exp.shift
      args = exp.shift
      body = exp.empty? ? nil : process(exp.shift)

      args = case args
             when 0 then
               " ||"
             else
               a = process(args)[1..-2]
               a = " |#{a}|" unless a.empty?
               a
             end

      b, e = if iter == "END"
               [ "{", "}" ]
             else
               [ "do", "end" ]
             end

      iter.sub!(/\(\)$/, '')

      # REFACTOR: ugh
      result = []
      result << "#{iter} {"
      result << args
      if body
        result << " #{body.strip} "
      else
        result << ' '
      end
      result << "}"
      result = result.join
      return result if result !~ /\n/ and result.size < LINE_LENGTH

      result = []
      result << "#{iter} #{b}"
      result << args
      result << LF
      if body
        result << indent(body.strip)
        result << LF
      end
      result << e
      result.join
    end

    def process_ivar(exp)
      exp.shift.to_s
    end

    def process_kwsplat(exp)
      "**#{process exp.shift}"
    end

    def process_lasgn(exp)
      s = "#{exp.shift}"
      s += " = #{process exp.shift}" unless exp.empty?
      s
    end

    def process_lit(exp)
      obj = exp.shift
      case obj
      when Range then
        "(#{obj.inspect})"
      else
        obj.inspect
      end
    end

    def process_lvar(exp)
      exp.shift.to_s
    end

    # s(:masgn, s(:array, s(:lasgn, :var), ...), s(:to_ary, <val>, ...))
    # s(:iter, <call>, s(:args, s(:masgn, :a, :b)), <body>)
    def process_masgn(exp)
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

    def process_match(exp)
      "#{process(exp.shift)}"
    end

    def process_match2(exp)
      lhs = process(exp.shift)
      rhs = process(exp.shift)
      "#{lhs} =~ #{rhs}"
    end

    def process_match3(exp)
      rhs = process(exp.shift)
      left_type = exp.first.sexp_type
      lhs = process(exp.shift)

      if ASSIGN_NODES.include? left_type
        "(#{lhs}) =~ #{rhs}"
      else
        "#{lhs} =~ #{rhs}"
      end
    end

    def process_module(exp)
      "#{exp.comments}module #{util_module_or_class(exp)}"
    end

    def process_next(exp)
      val = exp.empty? ? nil : process(exp.shift)
      if val
        "next #{val}"
      else
        "next"
      end
    end

    def process_nil(exp)
      "nil"
    end

    def process_not(exp)
      "(not #{process exp.shift})"
    end

    def process_nth_ref(exp)
      "$#{exp.shift}"
    end

    # [[:lvar, :b], [:arglist, [:lit, 1]], :"||", [:lit, 10]]
    def process_op_asgn1(exp)
      lhs = process(exp.shift)
      index = process(exp.shift)
      msg = exp.shift
      rhs = process(exp.shift)

      "#{lhs}[#{index}] #{msg}= #{rhs}"
    end

    # [[:lvar, :c], :var=, :"||", [:lit, 20]]
    def process_op_asgn2(exp)
      lhs = process(exp.shift)
      index = exp.shift.to_s[0..-2]
      msg = exp.shift

      rhs = process(exp.shift)

      "#{lhs}.#{index} #{msg}= #{rhs}"
    end

    # a &&= 1
    # [[:lvar, :a], [:lasgn, :a, [:lit, 1]]]
    def process_op_asgn_and(exp)
      exp.shift
      process(exp.shift).sub(/\=/, '&&=')
    end

    # a ||= 1
    # [[:lvar, :a], [:lasgn, :a, [:lit, 1]]]
    def process_op_asgn_or(exp)
      exp.shift
      process(exp.shift).sub(/\=/, '||=')
    end

    def process_or(exp)
      "(#{process exp.shift} or #{process exp.shift})"
    end

    def process_postexe(exp)
      "END"
    end

    def process_redo(exp)
      "redo"
    end

    def process_resbody exp
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

    def process_rescue exp
      body = process(exp.shift) unless exp.first.first == :resbody
      els  = process(exp.pop)   unless exp.last.first  == :resbody

      body ||= "# do nothing"
      simple = exp.size == 1 && exp.resbody.size <= 3 &&
        !exp.resbody.block &&
        !exp.resbody.return

      resbodies = []
      until exp.empty? do
        resbody = exp.shift
        simple &&= resbody[1] == s(:array)
        simple &&= resbody[2] != nil && resbody[2].node_type != :block
        resbodies << process(resbody)
      end

      if els
        "#{indent body}\n#{resbodies.join(LF)}\nelse\n#{indent els}"
      elsif simple
        resbody = resbodies.first.sub(/\n\s*/, ' ')
        "#{body} #{resbody}"
      else
        "#{indent body}\n#{resbodies.join(LF)}"
      end
    end

    def process_retry(exp)
      "retry"
    end

    def process_return(exp)
      if exp.empty?
        "return"
      else
        "return #{process exp.shift}"
      end
    end

    def process_sclass(exp)
      "class << #{process(exp.shift)}\n#{indent(process_block(exp))}\nend"
    end

    def process_self(exp)
      "self"
    end

    def process_splat(exp)
      if exp.empty?
        "*"
      else
        "*#{process(exp.shift)}"
      end
    end

    def process_str(exp)
      exp.shift.dump
    end

    def process_super(exp)
      args = finish exp

      "super(#{args.join(', ')})"
    end

    def process_svalue(exp)
      code = []
      until exp.empty? do
        code << process(exp.shift)
      end
      code.join(", ")
    end

    def process_to_ary(exp)
      process(exp.shift)
    end

    def process_true(exp)
      "true"
    end

    def process_undef(exp)
      "undef #{process(exp.shift)}"
    end

    def process_until(exp)
      cond_loop(exp, 'until')
    end

    def process_valias(exp)
      "alias #{exp.shift} #{exp.shift}"
    end

    def process_when(exp)
      src = []

      if self.context[1] == :array # ugh. matz! why not an argscat?!?
        val = process(exp.shift)
        exp.shift # empty body
        return "*#{val}"
      end

      until exp.empty?
        cond = process(exp.shift).to_s[1..-2]
        code = indent(finish(exp).join(LF))
        code = indent "# do nothing" if code =~ /\A\s*\Z/
        src << "when #{cond} then\n#{code.chomp}"
      end

      src.join(LF)
    end

    def process_while(exp)
      cond_loop(exp, 'while')
    end

    def process_xstr(exp)
      "`#{process_str(exp)[1..-2]}`"
    end

    def process_yield(exp)
      args = []
      until exp.empty? do
        args << process(exp.shift)
      end

      if args.empty?
        "yield"
      else
        "yield(#{args.join(', ')})"
      end
    end

    def process_zsuper(exp)
      "super"
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
      s.to_s.split(/\n/).map{|line| @indent + line}.join(LF)
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

    # Return the appropriate regexp flags for a given numeric code.
    def re_opt options
      bits = (0..8).map { |n| options[n] * 2**n }
      bits.delete 0
      bits.map { |n| Regexp::CODES[n] }.join
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
