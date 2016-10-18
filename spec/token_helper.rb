module TokenHelper
  def value_of_token(name)
    ReverseXSLT::Token::ValueOfToken.new(name)
  end

  def text_token(text)
    ReverseXSLT::Token::TextToken.new(text)
  end

  def if_token(name)
    res = ReverseXSLT::Token::IfToken.new(name)
    res.children = yield if block_given?
    res
  end

  def for_each_token(name)
    res = ReverseXSLT::Token::ForEachToken.new(name)
    res.children = yield if block_given?
    res
  end

  def tag_token(name)
    res = ReverseXSLT::Token::TagToken.new(name)
    res.children = yield if block_given?
    res
  end

  def parse(doc)
    ReverseXSLT.parse(doc)
  end

  def match(x, y, r = {})
    ReverseXSLT.match(x, y, r)
  end

  def tokenize(x)
    ReverseXSLT::Token::Token.tokenize(x)
  end
end
