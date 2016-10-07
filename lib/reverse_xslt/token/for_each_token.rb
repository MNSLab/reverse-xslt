module ReverseXSLT
  module Token
    class ForEachToken < Token
      def initialize(tag = '')
        name = extract_element_attribute(tag, 'select')

        super(:for_each, Token::tokenize(name))
      end
    end
  end
end
