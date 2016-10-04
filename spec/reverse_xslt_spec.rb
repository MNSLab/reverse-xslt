require 'spec_helper'

describe ReverseXSLT do
  it 'has a version number' do
    expect(ReverseXSLT::VERSION).not_to be nil
  end

  describe '.parse_node(doc)' do
    it 'parses tag node' do
      doc = Nokogiri::XML('<div></div>')

      ReverseXSLT::parse_node(doc.root).tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::TagToken)
        expect(result.value).to eq('div')
        expect(result.children).to be_empty
      end
    end

    it 'parses text node' do
      doc = Nokogiri::XML('<div>Hello World</div>')

      ReverseXSLT::parse_node(doc.root).children.first.tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::TextToken)
        expect(result.value).to eq('Hello World')
        expect(result.children).to be_empty
      end
    end

    it 'parses xsl:value-of node'

    it 'parses xsl:if node' do
      doc = Nokogiri::XML(%q[<xml xmlns:xsl="http://www.w3.org/1999/XSL/Transform"><xsl:if test="(//a:abra != '') and (//a:kadabra != '') and (//a:alakazam != '')"></xsl:if></xml>])

      ReverseXSLT::parse_node(doc.root.children.first).tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::IfToken)
        expect(result.value).to eq('abra_kadabra_alakazam')
        expect(result.children).to be_empty
      end
    end
    it 'parses xsl:for-each'

    it 'parses comments' do
      doc = Nokogiri::XML('<!-- hello world -->')

      expect(ReverseXSLT::parse_node(doc.children.first)).to be_nil
    end
  end

  describe '.parse(doc)' do
    it 'accepts nokogiri::XML as doc' do
      pending
      doc = Nokogiri::XML('<div></div>')

      expect {
        ReverseXSLT::parse(doc)
      }.to be_a(Token)
    end

    it 'accepts String as doc' do
      pending
      expect{
        ReverseXSLT::parse('<div></div>')
      }.to be_a(Token)
    end

    context 'doc has single root' do
      it 'returns token' do
        pending
        expect{
          ReverseXSLT::parse('<div></div>')
        }.to be_a(Token)
      end
    end

    context 'doc has multiply roots' do
      it 'returns list of tokens' do
        pending
        results = ReverseXSLT::parse('<a></a><b></b><c></c>')

        expect(results).to be_a(Array)
        expect(results.length).to eq(3)

        ['a', 'b', 'c'].each_with_index do |x,i|
          expect(results[i]).to be_a(Token::TagToken)
          expect(results[i].value).to eq(x)
        end
      end
    end
  end

  describe '::match?(xslt,xml)' do

  end

  describe '::match(xslt, xml)' do
    it 'throws exception on two conseciuting text nodes'
  end
end
