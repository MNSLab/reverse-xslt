module ReverseXSLT
  module Token
    class ValueOfToken < Token
      def initialize(tag)
        super(:if, tokenize(tag.attr('select')))
      end
    end
  end
end
