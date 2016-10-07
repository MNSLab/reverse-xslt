module ReverseXSLT
  module Token
    class Token
      attr_reader :type, :value
      attr_accessor :children

      def ==(other)
        self.class == other.class && self.type == other.type && self.value == other.value && self.children == other.children
      end
      
      def initialize(type, value)
        @type = type
        @value = value
        @children = []
      end

      def self.tokenize(text)
        text.gsub(/[a-z]+:/,'').gsub(/(?<=[^_a-z])(not|or|and)(?=[^_a-z])/,'_').gsub(/(?<=[^_a-z])(not|or|and)\z/,'_').gsub(/^(not|or|and)(?=[^_a-z])/,'_').gsub(/[^_a-z]/, '_').gsub(/[_]+/, '_').gsub(/\A_+/, '').gsub(/_+\z/, '')
      end
    end
  end
end

require 'reverse_xslt/token/tag_token'
require 'reverse_xslt/token/text_token'
require 'reverse_xslt/token/if_token'
require 'reverse_xslt/token/value_of_token'
require 'reverse_xslt/token/for_each_token'
