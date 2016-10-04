module ReverseXSLT
  module Token
    class TextToken < Token
      def initialize(tag)
        super(:text, tag.text)
      end
    end
  end
end
