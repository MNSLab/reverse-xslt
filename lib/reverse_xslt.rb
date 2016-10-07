require "reverse_xslt/version"
require 'reverse_xslt/token/token'
require 'reverse_xslt/error'

require 'nokogiri'

module ReverseXSLT

  # Parse XML/Nokogiri::XML into tokens hierarchy
  # @param doc [XML String / Nokogiri::XML] asd
  #
  # @example
  #
  # @return [Array<Token>]
  #
  def self.parse(doc)
    doc = Nokogiri::XML.fragment(doc) if doc.is_a? String

    doc.children.map do |child|
      parse_node(child)
    end
  end

  # Match XSLT document to XML document, return matched value-of tokens.
  #
  # @param xslt [Array<Token>]
  # @param xml [Array<Token>]
  #
  # @return [Hash] when xslt match xml, hash with all matched value-of tokens
  # @return [nil] when xslt doesn't match xml
  def self.match(xslt, xml)
    raise Error::IllegalMatchUse unless (xslt.is_a? Array) and (xml.is_a? Array)
    #
    # xslt = merge_text_tokens(xslt)
    # xml  = merge_text_tokens(xml)
    #
    # results = {}
    #
    # # INFO: v0.1 xslt,xml contains only TEXT, TAG, VALUE-OF tokens
    # matchings = []
    # while true
    #   tp1, tl1 = text_prefix(xslt)
    #   tp2, tl2 = text_prefix(xml)
    #
    #   raise ReverseXSLT::Error::MalformedTree if tp2.length > 1
    #   raise ReverseXSLT::Error::DisallowedMatch unless tp2.first.class == Token::TextToken or tp2.first.nil?
    #
    #   matchings << [tp1, (tp2.first && tp2.first.value) || '']
    #   hd1 = tl1.shift
    #   hd2 = tl2.shift
    #
    #   return nil if hd1.class != hd2.class
    #
    #   break if hd1.nil?
    #
    #   raise ReverseXSLT::Error::MalformedTree unless hd1.is_a? ReverseXSLT::Token::TagToken
    #
    #   return nil unless hd1.value == hd2.value
    #   res = match(hd1.children, hd2.children)
    #   return nil if res.nil?
    #
    #   merge_matchings!(results, res)
    #
    #   xslt, xml = tl1, tl2
    # end
    #
    # matchings.each do |m1, m2|
    #   res = text_matching(m1, m2)
    #   return nil if res.nil?
    #
    #   merge_matchings!(results, res)
    # end
    #
    # return results
    match_recursive([], xslt, [], xml)
  end

  # Check if xml match structure of xslt (could be generated from)
  # @param xslt []
  # @param xml []
  # @param exactly [Boolean]
  #
  # @return [Boolean] +xml+ match +xslt+
  def self.match?(xslt, xml)
    begin
      match(xslt, xml).is_a? Hash
    rescue
      false
    end
  end


  private

  # Parse single Nokogiri::XML::Node into single Token
  def self.parse_node(node)
    case node
    when Nokogiri::XML::Text
      Token::TextToken.new(node)
    when Nokogiri::XML::Element
      name = (node.namespace ? "#{node.namespace.prefix}:" : '') + node.name
      res = case name
      when 'xsl:if'
        Token::IfToken.new(node)
      when 'xsl:value-of'
        Token::ValueOfToken.new(node)
      when 'xsl:for-each'
        Token::ForEachToken.new(node)
      else
        if node.namespace.nil?
          Token::TagToken.new(node)
        else
          raise ArgumentError.new("Unknown node namespace: #{node.namespace}")
        end
      end

      res.children = node.children.map{|x| parse_node(x) }.compact
      res
    when Nokogiri::XML::Comment
      nil
    else
      raise ArgumentError.new("Unknown node class: #{node.class}")
    end
  end

  private

  # Match series of TextToken and ValueOfToken to TextToken
  # @param tokens [Array<Token>] array of TextToken and ValueOfToken
  # @param text [String] text token
  # @param prefix_match [Boolean] it is required to only match text prefix
  #
  # @return [Hash] hash of matched variables
  # @return [nil] when tokens doesn't match text
  def self.text_matching(tokens, text, prefix_match = false)
    # check for consecuting value-of tokens
    tokens.each_with_index do |x, i|
      raise Error::ConsecutiveValueOfToken if (i > 0) and (tokens[i-1].class == x.class)
    end

    # convert tokens to regexp
    used_names = []
    re = tokens.map do |token|
      case token
      when ReverseXSLT::Token::TextToken
        Regexp.quote(token.value.gsub(/\s+/, ' ').strip)
      when ReverseXSLT::Token::ValueOfToken
        raise Error::DuplicatedValueOfToken if used_names.include? token.value
        used_names << token.value
        "(?<#{token.value}>.*)"
      else
        raise Error::IllegalToken
      end
    end.join('\s*')

    # reduce series of whitespace
    text = text.gsub(/\s+/, ' ').strip

    re = '\A'+re+(prefix_match ? '' : '\z')

    res = text.match(Regexp.new(re))

    return nil if res.nil?

    res = Hash[res.names.map{|name| [name, res[name].strip]}]

    return res
  end

  # extract text (TextToken and ValueOfToken) prefix.
  # @param tokens [Array<Token>] array of tokens, this array isn't modified
  # @return [[Array<Token>, Array<Token>]] pair of array of text tokens and rest of tokens
  def self.text_prefix(tokens)
    index = 0
    while (index < tokens.length) and ((tokens[index].is_a? Token::TextToken) or (tokens[index].is_a? Token::ValueOfToken))
      index+=1
    end

    return [tokens[0, index], tokens[index, tokens.length-index]]
  end

  # Merge consecutive TextTokens in token array
  # @param tokens[Array<Token>] array of tokens
  # @return [Array<Token>] array of tokens where consecutive TextTokens are merged into single TextToken
  def self.merge_text_tokens(tokens)
    res = []
    queue = []
    tokens.each do |token|
      if token.is_a? Token::TextToken
        queue << token.value
      else
        unless queue.empty?
          res << Token::TextToken.new(queue.join ' ')
          queue.clear
        end
        res << token
      end
    end

    unless queue.empty?
      res << Token::TextToken.new(queue.join ' ')
      queue.clear
    end

    res
  end

  # Merge matching, checking for duplicated matchings
  # @param x [Hash]
  # @param y [Hash]
  #
  # @return [Hash]
  def self.merge_matchings!(x, y)
    raise Error::DuplicatedValueOfToken unless (x.keys & y.keys).empty?
    x.merge! y
  end

  #
  # XSLT document tree:
  # @param text_prefix [Array<TextToken/ValueOfToken>] text prefix - array of already red text/value-of tokens awaiting for matching
  # @param tokens_xslt [Array<Token>] res of tokens
  # XML document tree:
  # @param text [TextToken/nil] text prefix of xml document
  # @param tokens_xml [Array<Token>] rest of xml document starting with tag-token
  def self.match_recursive(text_prefix, tokens_xslt, text, tokens_xml)
    # puts "v"*100
    # puts text_prefix.inspect
    # puts tokens_xslt.inspect
    # puts text.inspect
    # puts tokens_xml.inspect
    # puts "^"*100


    # extract text tokens from xslt
    text_prefix_2, tokens_xslt = text_prefix(tokens_xslt)
    text_prefix = merge_text_tokens(text_prefix + text_prefix_2) # update text prefix

    # extract text tokens from xml
    text_prefix_2, tokens_xml = text_prefix(tokens_xml)
    text = merge_text_tokens(text + text_prefix_2)

    raise Error::MalformedTree if text.length > 1
    raise Error::DisallowedMatch unless text.first.is_a? Token::TextToken or text.first.nil?



    # read first non text token
    token = tokens_xslt.shift
    # TODO: we should check for empty array inside of nil token
    case token
    when Token::TagToken
      other = tokens_xml.shift

      return nil unless other.class == Token::TagToken # there is no tag in xml document
      return nil unless other.value == token.value # different tag name

      # match text prefixes
      text_matching = text_matching(text_prefix, (text.first && text.first.value) || '')
      return nil if text_matching.nil?

      # match tags content
      tags_matching = match(token.children, other.children)

      # match rest of document
      recursive_matching = match_recursive([], tokens_xslt, [], tokens_xml)

      merge_matchings!(text_matching, tags_matching)
      merge_matchings!(text_matching, recursive_matching)

      return text_matching
    when Token::IfToken
      # matching without IF
      res_1 = match_recursive(text_prefix, tokens_xslt, text, tokens_xml)

      # matching with IF
      res_2 = match_recursive(text_prefix, token.children + tokens_xslt, text, tokens_xml)

      if res_1.nil?
        return nil if res_2.nil?
        return res_2
      else
        return res_1 if res_2.nil?
        raise Error::AmbiguousMatch
      end
    when Token::ForEachToken

    when nil # end of XSLT document
      return nil unless tokens_xml.first.class == token.class

      return text_matching(text_prefix, (text.first && text.first.value) || '')
    else
      raise ArgumentError('Aaaaaaaa!!!!')
    end
  end
end
