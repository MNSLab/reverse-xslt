module ReverseXSLT::Token
  class TagToken < Token
    def initialize(tag)
      name = if tag.is_a? Nokogiri::XML::Element
        tag.name
      else
        tag
      end

      super(:tag, name)
    end
  end
end
