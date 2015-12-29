require "sexp2ruby/token"

module Sexp2Ruby

  # Given a bunch of tokens, produces a string. Not sure what the right name for
  # this is, but it sounds like the opposite of a lexer.
  class Delexer
    INDENT_WIDTH = 2
    LF = "\n"
    MAX_LINE_LEN = 80
    SPACE = " "

    def initialize
      @tokens = []
      @lines = []
      @n = 0
    end

    def push(t)
      raise TypeError unless t.is_a?(Token)
      @tokens.push(t)
    end

    # @param d [int] Indentation depth, i.e. number of spaces.
    def to_s(d)
      @d = d
      build_lines
      @lines.join(LF)
    end

    private

    def append(str)
      @lines[@n] << str
    end

    def build_lines
      @lines = [SPACE * @d]
      indent_stack = []
      0.upto(@tokens.length - 1) do |i|
        t = @tokens[i]
        s = t.to_s

        # Dedent? (decrease indentation)
        if t.type == :tRPAREN && indent_stack.last == :tLPAREN
          dedent
          indent_stack.pop
          new_line
        end

        # Break long line? (increase indentation)
        if break?(i, s)
          indent
          if @tokens[i - 1].type == :tLPAREN
            indent_stack.push(:tLPAREN)
          end
          new_line
        end

        append(s)
      end
    end

    # Should we break before appending `str`?
    def break?(i, str)
      return false if i == 0 # Print at least one token before breaking
      potential_len = @lines[@n].length + str.length
      @tokens[i - 1].can_break_after? && potential_len >= MAX_LINE_LEN
    end

    def dedent
      @d -= INDENT_WIDTH
    end

    def indent
      @d += INDENT_WIDTH
    end

    def new_line
      @n += 1
      @lines[@n] = SPACE * @d
    end
  end
end
