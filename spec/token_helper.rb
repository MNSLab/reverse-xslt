module TokenHelper
  def value_of_token(name)
    ReverseXSLT::Token::ValueOfToken.new(name)
  end

  def text_token(text)
    ReverseXSLT::Token::TextToken.new(text)
  end

  def if_token(name, &block)
    res = ReverseXSLT::Token::IfToken.new(name)
    res.children = block.call if block_given?
    res
  end

  def for_each_token(name, &block)
    res = ReverseXSLT::Token::ForEachToken.new(name)
    res.children = yield if block_given?
    res
  end

  def tag_token(name, &block)
    res = ReverseXSLT::Token::TagToken.new(name)
    res.children = yield if block_given?
    res
  end

  def parse(doc)
    ReverseXSLT::parse(doc)
  end

  def match(x, y)
    ReverseXSLT::match(x, y)
  end

end
