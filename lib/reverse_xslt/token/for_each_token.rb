module ReverseXSLT
  module Token
    class ForEachToken < Token
      def initialize(tag)
        super(:for_each, Token::tokenize(tag.attr('select')))
      end
    end
  end
end
