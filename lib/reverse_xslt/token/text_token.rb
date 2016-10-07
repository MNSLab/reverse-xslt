module ReverseXSLT
  module Token
    class TextToken < Token
      def initialize(tag = '')
        text = tag.respond_to?(:text) ? tag.text : tag.to_s

        super(:text, text)
      end
    end
  end
end
