require 'reverse_xslt/version'
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
  # @param xslt [Array<Token>] XSLT document (contains any token)
  # @param xml [Array<Token>] XML document (contains only Text and Tag tokens)
  # @param regexp [Hash<String, Regexp>] additional regexp for value-of token (replace default match all)
  #
  # @return [Hash] when xslt match xml, hash with all matched value-of tokens
  # @return [nil] when xslt doesn't match xml
  def self.match(xslt, xml, _regexp = {})
    raise Error::IllegalMatchUse unless (xslt.is_a? Array) && (xml.is_a? Array)

    matching = match_recursive([], xslt, [], xml)
    return nil if matching.nil?
    # binding.pry
    extract_matching(matching)
  end

  # Check if xml match structure of xslt (could be generated from)
  # @param xslt []
  # @param xml []
  # @param exactly [Boolean]
  #
  # @return [Boolean] +xml+ match +xslt+
  def self.match?(xslt, xml)
    match(xslt, xml).is_a? Hash
  rescue
    false
  end

  private

  # Parse single Nokogiri::XML::Node into single Token
  def self.parse_node(node)
    case node
    when Nokogiri::XML::Text
      Token::TextToken.new(node)
    when Nokogiri::XML::Element
      name = (node.namespace ? "#{node.namespace.prefix}:" : '') + node.name

      res =
        case name
        when 'xsl:if'
          Token::IfToken.new(node)
        when 'xsl:value-of'
          Token::ValueOfToken.new(node)
        when 'xsl:for-each'
          Token::ForEachToken.new(node)
        else
          Token::TagToken.new(node)
        end

      res.children = node.children.map { |x| parse_node(x) }.compact
      res
    when Nokogiri::XML::Comment
      nil
    else
      raise ArgumentError.new("Unknown node class: #{node.class}")
    end
  end

  # Match series of TextToken and ValueOfToken to TextToken
  #
  # @param tokens [Array<Token>] array of TextToken and ValueOfToken
  # @param text [String] text token
  # @param prefix_match [Boolean] it is required to only match text prefix
  #
  # @return [Hash] hash of matched variables
  #   Hash[if-token] = {_: 'text of whole matched tree', other matched elements}
  #   Hash[for-each-token] = [{first occurence}, {second occurence}, ..]
  #   Hash[value-of-token] = 'text'
  #   tag-token and text-token don't have match entry
  # @return [nil] when tokens doesn't match text
  #
  def self.text_matching(tokens, text, prefix_match = false)
    # check for consecuting value-of tokens
    tokens.each_with_index do |x, i|
      raise Error::ConsecutiveValueOfToken if (i > 0) && (tokens[i - 1].class == x.class)
    end

    # convert tokens to regexp
    used_names = []
    re = tokens.map do |token|
      case token
      when Token::TextToken
        Regexp.quote(token.value.gsub(/\s+/, ' ').strip)
      when Token::ValueOfToken
        raise Error::DuplicatedTokenName if used_names.include? token.value
        used_names << token.value
        "(?<#{token.value}>.*)"
      else
        raise Error::IllegalToken
      end
    end.join('\s*')

    # reduce series of whitespace
    text = text.gsub(/\s+/, ' ').strip

    re = '\A' + re + (prefix_match ? '' : '\z')

    matching = text.match(Regexp.new(re))

    return nil if matching.nil?

    # res = Hash[res.names.map{|name| [name, res[name].strip]}]

    # return res
    tokens.each do |token|
      if token.is_a? Token::ValueOfToken
        token.matching = matching[token.value].strip
      end
    end
  end

  # extract text (TextToken and ValueOfToken) prefix.
  # @param tokens [Array<Token>] array of tokens, this array isn't modified
  # @return [[Array<Token>, Array<Token>]] pair of array of text tokens and rest of tokens
  def self.text_prefix(tokens)
    index = 0
    while (index < tokens.length) && ((tokens[index].is_a? Token::TextToken) || (tokens[index].is_a? Token::ValueOfToken))
      index += 1
    end

    [tokens[0, index], tokens[index, tokens.length - index]]
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
    raise Error::DuplicatedTokenName unless (x.keys & y.keys).empty?
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
    # extract text tokens from xslt
    text_prefix_2, tokens_xslt = text_prefix(tokens_xslt)
    text_prefix = merge_text_tokens(text_prefix + text_prefix_2) # update text prefix

    # extract text tokens from xml
    text_prefix_2, tokens_xml = text_prefix(tokens_xml)
    text = merge_text_tokens(text + text_prefix_2)

    raise Error::MalformedTree if text.length > 1
    raise Error::DisallowedMatch unless text.first.is_a?(Token::TextToken) || text.first.nil?

    # read first non text token
    token = tokens_xslt.shift

    # TODO: we should check for empty array instead of nil token
    case token
    when Token::TagToken
      other = tokens_xml.shift

      return nil unless other.class == Token::TagToken # there is no tag in xml document
      return nil unless other.value == token.value # different tag name

      # match text prefixes
      text_matching = text_matching(text_prefix, (text.first && text.first.value) || '')
      return nil if text_matching.nil?

      # match tags content
      tag_matching = match(token.children, other.children)
      return nil if tag_matching.nil?
      token.matching = tag_matching

      # match rest of document
      recursive_matching = match_recursive([], tokens_xslt, [], tokens_xml)
      return nil if recursive_matching.nil?

      return text_matching + [token] + recursive_matching
    when Token::IfToken
      # matching without IF
      res_1 = match_recursive(text_prefix, tokens_xslt, text, tokens_xml)

      # matching with IF
      clone = tokens_xslt.map(&:clone)
      res_2 = match_recursive(text_prefix, token.children + clone, text, tokens_xml)

      if res_1.nil?
        return nil if res_2.nil?

        token.matching = extract_text(token.children)

        return [token] + clone
      else
        raise Error::AmbiguousMatch unless res_2.nil?
        token.matching = nil
        return [token] + tokens_xslt
      end
    when Token::ForEachToken
      # TODO: implement for-each-token matching
    when nil # end of XSLT document
      return nil unless tokens_xml.first.class == token.class

      return text_matching(text_prefix, (text.first && text.first.value) || '')
    else
      raise ArgumentError('Aaaaaaaa!!!!')
    end
  end

  def self.extract_matching(tokens)
    res = {}
    tokens.each do |token|
      case token
      when Token::TagToken
        merge_matchings!(res, token.matching)
      when Token::ForEachToken, Token::ValueOfToken
        unless token.matching.nil?
          raise Error::DuplicatedTokenName if res[token.value]
          res[token.value] = token.matching
        end
      when Token::IfToken
        unless token.matching.nil?
          raise Error::DuplicatedTokenName if res[token.value]
          res[token.value] = token.matching
          merge_matchings!(res, extract_matching(token.children))
        end
      end
    end
    res
  end

  def self.extract_text(tokens)
    tokens.map do |token|
      case token
      when Token::TextToken
        token.value
      when Token::IfToken, Token::ForEachToken, Token::ValueOfToken
        token.matching
      when Token::TagToken
        extract_text(token.children)
      end
    end.compact.join(' ').gsub(/\s+/, ' ').strip
  end
end
