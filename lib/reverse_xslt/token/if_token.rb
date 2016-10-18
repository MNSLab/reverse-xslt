module ReverseXSLT
  module Token
    # Wrapper for xsl:if token
    # It represents object that can appear zero or one times.
    #
    # Example:
    #   <xsl:if test="//a:is_zero = '0'">yes</xsl:if>
    #
    class IfToken < Token
      # Create new IfToken
      #
      # @param tag [String] token name
      # @param tag [Nokogiri::XML::Element] XML element, their `test` attribute
      #   will be used to name token
      #
      def initialize(tag = '')
        # if element is created from real xsl:if tag than prefix it with 'if'
        name = (tag.respond_to?(:attr) ? 'if ' : '')+extract_element_attribute(tag, 'test')

        super(:if, Token.tokenize(name))
      end
    end
  end
end
