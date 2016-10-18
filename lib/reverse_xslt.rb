# TODO: ability to eat single text-token
require 'reverse_xslt/version'
require 'reverse_xslt/token/token'
require 'reverse_xslt/error'

require 'nokogiri'

# Namespace module for xslt matching functions
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
  # @param regexp [Hash<String, Regexp>] additional regexp for value-of token
  #   (replace default match all)
  #
  # @return [Hash] when xslt match xml, hash with all matched value-of tokens
  # @return [nil] when xslt doesn't match xml
  def self.match(xslt, xml, regexp = {})
    raise Error::IllegalMatchUse unless (xslt.is_a? Array) && (xml.is_a? Array)

    matching = match_recursive([], xslt, [], xml, regexp)
    return nil if matching.nil?

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

  private_class_method

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
      raise ArgumentError, "Unknown node class: #{node.class}"
    end
  end

  # Match series of TextToken and ValueOfToken to TextToken
  #
  # @param tokens [Array<Token>] array of TextToken and ValueOfToken
  # @param text [String] text token
  # @param regexp [Hash<String, Regexp>] define specific regexp for given token
  # @param prefix [Boolean] match only prefix of text
  #
  # @return [Array<ValueOfToken>] array of value-of-tokens in tokens list,
  #   they have filled up matching field.
  # @return [nil] when tokens doesn't match text
  #
  def self.match_text_nodes(tokens, text, regexp = {}, prefix = false)
    # check for consecuting value-of tokens
    raise Error::ConsecutiveValueOfToken if tokens
      .map{ |t| (t.is_a? Token::ValueOfToken) && regexp[t.value].nil? }
      .each_cons(2).any? {|a, b| a && b }

    tokens = merge_text_tokens(tokens)

    # convert tokens to regexp
    names = {}
    last = nil

    re = tokens.map do |token|
      res = case token
      when Token::TextToken
        Regexp.quote(token.value.gsub(/\s+/, ' ').strip)
      when Token::ValueOfToken
        #raise Error::DuplicatedTokenName if used_names.include? token.value
        name = "v#{names.size}"
        names[name] = token
        r = regexp[token.value] || '.*'
        "(?<#{name}>#{r})"
      else
        raise Error::IllegalToken
      end
      if last.is_a?(Token::ValueOfToken) and token.is_a?(Token::ValueOfToken)
        res = "\\s+#{res}"
      else
        res = "\\s*#{res}" unless last.nil?
      end
      last = token
      res
    end.join('')

    # reduce series of whitespace
    text = text.gsub(/\s+/, ' ').strip

    re = '\A' + re + (prefix ? '' : '\z')
    puts re
    matching = text.match(Regexp.new(re))

    return nil if matching.nil?

    unless prefix
      names.each do |k, v|
        v.matching = matching[k].strip
      end
    end

    tokens
  end

  # extract text (TextToken and ValueOfToken) prefix.
  # @param tokens [Array<Token>] array of tokens, this array isn't modified
  # @return [[Array<Token>, Array<Token>]] pair of array of text tokens and
  #   rest of tokens
  def self.text_prefix(tokens)
    index = 0

    index += 1 while (index < tokens.length) && tokens[index].textual_token?

    [tokens[0, index], tokens[index, tokens.length - index]]
  end

  # Merge consecutive TextTokens in token array
  # @param tokens[Array<Token>] array of tokens
  # @return [Array<Token>] array of tokens where consecutive TextTokens
  #   are merged into single TextToken
  def self.merge_text_tokens(tokens)
    res = []
    queue = []
    tokens.each do |token|
      if token.is_a? Token::TextToken
        queue << token.value
      else
        unless queue.empty?
          res << Token::TextToken.new(queue.join(' '))
          queue.clear
        end
        res << token
      end
    end

    unless queue.empty?
      res << Token::TextToken.new(queue.join(' '))
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
    (x.keys & y.keys).each do |k|
      Error::DuplicatedTokenName.new("#{k}: #{x[k]}, #{y[k]}") if x[k] != y[k]
    end

    x.merge! y
  end

  #
  # XSLT document tree:
  # @param text_prefix [Array<TextToken/ValueOfToken>] text prefix -
  #   array of already red text/value-of tokens awaiting for matching
  # @param tokens_xslt [Array<Token>] res of tokens
  #
  # XML document tree:
  # @param text [TextToken/nil] text prefix of xml document
  # @param tokens_xml [Array<Token>] rest of xml document, starts with tag-token
  def self.match_recursive(text_prefix, tokens_xslt, text, tokens_xml, regexp)
    # extract text tokens from xslt
    text_prefix_2, tokens_xslt = text_prefix(tokens_xslt)

    # update text prefix
    text_prefix = merge_text_tokens(text_prefix + text_prefix_2)

    # extract text tokens from xml
    text_prefix_2, tokens_xml = text_prefix(tokens_xml)
    text = merge_text_tokens(text + text_prefix_2)

    raise Error::MalformedTree if text.length > 1
    unless text.first.is_a?(Token::TextToken) || text.first.nil?
      raise Error::DisallowedMatch
    end

    # read first non text token
    token = tokens_xslt.shift

    # TODO: we should check for empty array instead of nil token

    case token
    when Token::TagToken
      other = tokens_xml.shift

      # XML documents ends prematurely
      return nil unless other.class == Token::TagToken

      return nil unless other.value == token.value # different tag name

      # match text prefixes
      text_matching = match_text_nodes(
        text_prefix,
        (text.first && text.first.value) || '',
        regexp
      )
      return nil if text_matching.nil?

      # match tags content
      tag_matching = match(token.children, other.children)
      return nil if tag_matching.nil?
      token.matching = tag_matching

      # match rest of document
      recursive_matching = match_recursive([], tokens_xslt, [], tokens_xml, regexp)
      return nil if recursive_matching.nil?

      return text_prefix + [token] + recursive_matching
    when Token::IfToken
      # matching without IF
      no_if_branch = match_recursive(text_prefix, tokens_xslt, text, tokens_xml, regexp)

      # matching with IF
      #clone = tokens_xslt.map(&:clone)

      if_branch = match_recursive(
        text_prefix,
        token.children + tokens_xslt,
        text,
        tokens_xml,
        regexp
      )

      if no_if_branch.nil?
        return nil if if_branch.nil?

        token.matching = extract_text(token.children)

        return [token] + tokens_xslt
      else
        raise Error::AmbiguousMatch unless if_branch.nil?
        match_recursive(text_prefix, tokens_xslt, text, tokens_xml, regexp)
        token.matching = nil
        return [token] + tokens_xslt
      end
    when Token::ForEachToken
      # Zero occurences of for-each token
      no_foreach_branch = match_recursive(text_prefix, tokens_xslt, text, tokens_xml, regexp)

      unless no_foreach_branch.nil?
        token.matching = []
        return [token] + tokens_xslt
      end

      # Recursivly one occurence of for-each token
      for_each_clone = token.clone
      x = self.text_prefix(text_prefix + token.children).first

      if match_text_nodes(x, (text.first && text.first.value) || '', regexp, true)
        foreach_branch = match_recursive(
          text_prefix,
          token.children + [for_each_clone] + tokens_xslt,
          text,
          tokens_xml,
          regexp
        )
      else
        foreach_branch = nil
      end

      return nil if foreach_branch.nil?
      token.matching = [extract_matching(token.children)] + for_each_clone.matching

      return [token] + tokens_xslt
    when nil # end of XSLT document
      return nil unless tokens_xml.first.class == token.class

      return match_text_nodes(text_prefix, (text.first && text.first.value) || '', regexp)
    else
      raise ArgumentError('Aaaaaaaa!!!!')
    end
  end

  # TODO: ?
  # @return [Hash<String, ..>]
  #   Hash[if-token] ='text of whole matched tree'
  #   Hash[for-each-token] = [{first occurence}, {second occurence}, ..]
  #   Hash[value-of-token] = 'text'
  #   tag-token and text-token don't have match entry
  def self.extract_matching(tokens)
    res = {}
    tokens.each do |token|
      case token
      when Token::TagToken
        merge_matchings!(res, token.matching)
      when Token::ForEachToken, Token::ValueOfToken
        unless token.matching.nil?
          if res[token.value] and res[token.value] != token.matching
            raise Error::DuplicatedTokenName.new(token.value) if res[token.value]
          end
          res[token.value] = token.matching
        end
      when Token::IfToken
        unless token.matching.nil?
          raise Error::DuplicatedTokenName.new(token.value) if res[token.value]
          res[token.value] = token.matching
          merge_matchings!(res, extract_matching(token.children))
        end
      end
    end
    res
  end

  # TODO: add comment
  def self.extract_text(tokens)
    tokens.map do |token|
      case token
      when Token::TextToken
        token.value
      when Token::IfToken, Token::ValueOfToken
        token.matching
      when Token::ForEachToken
        # TODO: for-each-token should return consistent extracted_text not a hash
        token.matching.map{|x| 'x'}.join(' ')
      when Token::TagToken
        extract_text(token.children)
      end
    end.compact.join(' ').gsub(/\s+/, ' ').strip
  end
end
