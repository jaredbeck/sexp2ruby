module Sexp2Ruby
  RSpec.describe Delexer do
    let(:delexer) { described_class.new }

    context "no tokens" do
      it "returns the empty string" do
        expect(delexer.to_s(0)).to eq("")
      end
    end

    context "a tSTRING" do
      it "returns the string" do
        delexer.push(Token.new(:tSTRING, '"banana"'))
        expect(delexer.to_s(0)).to eq('"banana"')
      end
    end

    context "a one-line method call" do
      it "returns a one-line string" do
        [
          Token.new(:tIDENTIFIER, "banana"),
          Token.new(:tLPAREN, "("),
          Token.new(:tSTRING, '"kiwi"'),
          Token.new(:tRPAREN, ")"),
        ].each do |t| delexer.push(t) end
        expect(delexer.to_s(0)).to eq("banana(\"kiwi\")")
      end
    end

    context "a method call that is too big for one line" do
      it "returns a multi-line string" do
        method_name = "x" * 79
        argument = '"kiwi"'
        [
          Token.new(:tIDENTIFIER, method_name),
          Token.new(:tLPAREN, "("),
          Token.new(:tSTRING, argument),
          Token.new(:tRPAREN, ")"),
        ].each do |t| delexer.push(t) end
        expect(delexer.to_s(0)).to eq(
          format("%s(\n  %s\n)", method_name, argument)
        )
      end
    end
  end
end
