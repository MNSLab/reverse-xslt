module ReverseXSLT
  module Token
    # Wrapper for normal xml tag
    #
    # Example:
    #  <div>...</div>
    class TagToken < Token
      def initialize(tag = '')
        name = tag.respond_to?(:name) ? tag.name : tag

        super(:tag, name)
      end
    end
  end
end
