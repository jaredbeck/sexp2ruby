module Sexp2Ruby
  module Node
    class Dregx < Base
      def to_s(exp)
        options = re_opt exp.pop if Fixnum === exp.last
        "/" << util_dthing(:dregx, exp) << "/#{options}"
      end

      private

      # Return the appropriate regexp flags for a given numeric code.
      def re_opt options
        bits = (0..8).map { |n| options[n] * 2**n }
        bits.delete 0
        bits.map { |n| Regexp::CODES[n] }.join
      end
    end
  end
end
