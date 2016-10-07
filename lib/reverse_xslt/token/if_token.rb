module ReverseXSLT
  module Token
    class IfToken < Token
      # Create new IfToken
      #
      # @param tag [String] token name
      # @param tag [Nokogiri::XML::Element] XML element, its `test` attribute will be used to name token
      #
      def initialize(tag)
        name = if tag.is_a? Nokogiri::XML::Element
          Token::tokenize(tag.attr('test'))
        else
          tag.to_s
        end

        super(:if, Token::tokenize(name))
      end
    end
  end
end
