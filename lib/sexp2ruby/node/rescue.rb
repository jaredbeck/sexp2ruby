module Sexp2Ruby
  module Node
    class Rescue < Base
      def to_s(exp)
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
    end
  end
end
