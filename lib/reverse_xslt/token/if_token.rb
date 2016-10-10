module ReverseXSLT
  module Token
    class IfToken < Token
      # Create new IfToken
      #
      # @param tag [String] token name
      # @param tag [Nokogiri::XML::Element] XML element, its `test` attribute will be used to name token
      #
      def initialize(tag = '')
        name = extract_element_attribute(tag, 'test')

        super(:if, Token.tokenize(name))
      end
    end
  end
end
