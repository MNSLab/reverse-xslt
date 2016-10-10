module ReverseXSLT
  module Token
    # Wrapper for xslt:for-each token.
    # This token represents something that can appear zero or more times.
    #
    # Example:
    #   <xsl:for-each select="//a:items">
    #     <xsl:value-of select="a:value" />
    #   </xsl:for-each>
    #
    class ForEachToken < Token
      def initialize(tag = '')
        name = extract_element_attribute(tag, 'select')

        super(:for_each, Token.tokenize(name))
      end
    end
  end
end
