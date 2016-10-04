module ReverseXSLT
  module Token
    class ValueOfToken < Token
      def initialize(tag)
        super(:value_of, Token::tokenize(tag.attr('select')))
      end
    end
  end
end
