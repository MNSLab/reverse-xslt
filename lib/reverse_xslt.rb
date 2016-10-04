require "reverse_xslt/version"
require 'reverse_xslt/token/token'

require 'nokogiri'

module ReverseXSLT

  # Parse XML/Nokogiri::XML into tokens hierarchy
  # @param doc [XML String / Nokogiri::XML] asd
  #
  # @example
  #
  # @return [Token]
  # @return [Array<Token>]
  #
  def self.parse(doc)

  end

  #
  # @param xslt [Array<Token>]
  # @param xml [Array<Token>]
  # @param exactly [Boolean]
  #
  # @return ?
  def self.match(xslt, xml, exactly = true)

  end

  # Check if xml match structure of xslt (could be generated from)
  # @param xslt []
  # @param xml []
  # @param exactly [Boolean]
  #
  # @return [Boolean] +xml+ match +xslt+
  def self.match?(xslt, xml, exactly = true)

  end


  private

  # Parse single Nokogiri::XML::Node into single Token
  def self.parse_node(node)
    case node
    when Nokogiri::XML::Text
      Token::TextToken.new(node)
    when Nokogiri::XML::Element
      puts "="*100+"#{node.namespace}"+"="*100
      res = case (node.namespace && node.namespace.prefix)
      when nil
        Token::TagToken.new(node)
      when 'xsl'
        case node.name
        when 'if'
          Token::IfToken.new(node)
        when 'value-of'
          Token::ValueOfToken.new(node)
        when 'for-each'
          Token::ForEachToken.new(node)
        else
          raise "Unknown xsl node name: #{node.name}"
        end
      else
        raise ArgumentError.new("Unknown node namespace: #{node.namespace}")
      end

      res.children = node.children.map{|x| parse_node(x) }.compact
      res
    when Nokogiri::XML::Comment
      nil
    else
      raise ArgumentError.new("Unknown node class: #{node.class}")
    end

  end
end
