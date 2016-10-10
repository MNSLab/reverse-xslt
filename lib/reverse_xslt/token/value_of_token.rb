module ReverseXSLT
  module Token
    # Wrapper for xsl:value-of token
    # This token can receive any value
    #
    # Example:
    #   <xsl:value-of select="//a:hour_now"/>
    class ValueOfToken < Token
      def initialize(tag = '')
        name = extract_element_attribute(tag, 'select')

        super(:value_of, Token.tokenize(name))
      end
    end
  end
end
