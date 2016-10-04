module ReverseXSLT::Token
  class TagToken < Token
    def initialize(tag)
      super(:tag, tag.name)
    end
  end
end
