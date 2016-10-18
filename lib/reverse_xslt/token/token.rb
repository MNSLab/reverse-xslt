module ReverseXSLT
  module Token
    # Wrapper for different XSLT/XML nodes
    class Token
      # @return [Symbol] type of token
      attr_reader :type

      # @return [String] their meaning depends on token type
      attr_reader :value

      # @return [Array<Token>] list of token children in parse tree
      attr_accessor :children

      # @return [Hash, String, Array] object contains matching data after .match
      attr_accessor :matching

      def ==(other)
        self.class == other.class && type == other.type &&
          value == other.value && children == other.children
      end

      def initialize(type, value)
        @type = type
        @value = value
        @children = []
        @matching = nil
      end

      def clone
        res = self.class.new
        res.instance_variable_set('@type', type)
        res.instance_variable_set('@value', value)
        res.children = children.map(&:clone)
        res
      end

      def self.tokenize(text)
        text
          .gsub(/'.*?'/, '')
          .gsub(/".*?"/, '')
          .gsub(/[a-z]+:/, '')
          .gsub(/(?<=[^_a-z0-9])(not|or|and)(?=[^_a-z0-9])/, '_')
          .gsub(/(?<=[^_a-z0-9])(not|or|and)\z/, '_')
          .gsub(/^(not|or|and)(?=[^_a-z0-9])/, '_')
          .gsub(/[^_a-z0-9]/, '_')
          .gsub(/[_]+/, '_')
          .gsub(/\A_+/, '')
          .gsub(/_+\z/, '')
      end

      def textual_token?
        (is_a? TextToken) || (is_a? ValueOfToken)
      end

      private

      def extract_element_attribute(element, attr)
        if element.respond_to? :attr
          element.attr(attr)
        else
          element.to_s
        end
      end
    end
  end
end

require 'reverse_xslt/token/tag_token'
require 'reverse_xslt/token/text_token'
require 'reverse_xslt/token/if_token'
require 'reverse_xslt/token/value_of_token'
require 'reverse_xslt/token/for_each_token'
