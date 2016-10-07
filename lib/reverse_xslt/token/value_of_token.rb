module ReverseXSLT
  module Token
    class ValueOfToken < Token
      def initialize(tag)
        name = if tag.is_a? Nokogiri::XML::Element
          tag.attr('select')
        else
          tag.to_s
        end

        super(:value_of, Token::tokenize(name))
      end
    end
  end
end
