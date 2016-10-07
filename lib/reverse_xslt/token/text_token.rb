module ReverseXSLT
  module Token
    class TextToken < Token
      def initialize(tag)
        text = if tag.is_a? Nokogiri::XML::Text
          tag.text
        else
          tag.to_s
        end

        super(:text, text)
      end
    end
  end
end
