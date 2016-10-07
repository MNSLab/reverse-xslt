module ReverseXSLT
  module Token
    class ValueOfToken < Token
      def initialize(tag = '')
        name = extract_element_attribute(tag, 'select')

        super(:value_of, Token::tokenize(name))
      end
    end
  end
end
