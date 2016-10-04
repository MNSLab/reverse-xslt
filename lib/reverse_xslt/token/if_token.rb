module ReverseXSLT
  module Token
    class IfToken < Token
      def initialize(tag)
        super(:if, Token::tokenize(tag.attr('test')))
      end
    end
  end
end
