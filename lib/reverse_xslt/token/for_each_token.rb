module ReverseXSLT
  module Token
    class ForEachToken < Token
      def initialize(tag = '')
        name = if tag.is_a? Nokogiri::XML::Element
          tag.attr('select')
        else
          tag.to_s
        end

        super(:for_each, Token::tokenize(name))
      end
    end
  end
end
