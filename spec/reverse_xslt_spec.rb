require 'spec_helper'

describe ReverseXSLT do
  it 'has a version number' do
    expect(ReverseXSLT::VERSION).not_to be nil
  end

  describe '.parse_node(doc)' do
    let(:for_each_node) { %q[<xsl:for-each select="//a:przeprowadza_wapolnie_podmiot/a:podmiot[not(../../../.. != '')]"></xsl:for-each>] }
    let(:tag_node) { '<div></div>' }
    let(:text_node) { 'Hello World' }
    let(:if_node) { %q[<xsl:if test="(//a:abra != '') and (//czary:kadabra != '') and (//mary:alakazam != '')"></xsl:if>] }
    let(:value_of_node) { %q[<xsl:value-of select="//a:abra_kadabra"/>]}
    let(:comment_node) { '<!-- hello world -->' }
    let(:xml) { %q[<xml xmlns:xsl="http://www.w3.org/1999/XSL/Transform">%s</xml>] }

    it 'parses tag node' do
      doc = Nokogiri::XML(tag_node)

      ReverseXSLT::parse_node(doc.root).tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::TagToken)
        expect(result.type).to be(:tag)
        expect(result.value).to eq('div')
        expect(result.children).to be_empty
      end
    end

    it 'parses text node' do
      doc = Nokogiri::XML('<div>%s</div>' % text_node)

      ReverseXSLT::parse_node(doc.root).children.first.tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::TextToken)
        expect(result.type).to be(:text)
        expect(result.value).to eq('Hello World')
        expect(result.children).to be_empty
      end
    end

    it 'parses xsl:value-of node' do
      doc = Nokogiri::XML(xml % value_of_node)

      ReverseXSLT::parse_node(doc.root.children.first).tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::ValueOfToken)
        expect(result.type).to be(:value_of)
        expect(result.value).to eq('abra_kadabra')
        expect(result.children).to be_empty
      end
    end

    it 'parses xsl:if node' do
      doc = Nokogiri::XML(xml % if_node)

      ReverseXSLT::parse_node(doc.root.children.first).tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::IfToken)
        expect(result.type).to be(:if)
        expect(result.value).to eq('abra_kadabra_alakazam')
        expect(result.children).to be_empty
      end
    end
    it 'parses xsl:for-each' do
      doc = Nokogiri::XML(xml % for_each_node)

      ReverseXSLT::parse_node(doc.root.children.first).tap do |result|
        expect(result).to be_a(ReverseXSLT::Token::ForEachToken)
        expect(result.type).to be(:for_each)
        expect(result.value).to eq('przeprowadza_wapolnie_podmiot_podmiot')
        expect(result.children).to be_empty
      end
    end

    it 'parses comments' do
      doc = Nokogiri::XML(comment_node)

      expect(ReverseXSLT::parse_node(doc.children.first)).to be_nil
    end

    it 'parses children nodes' do
      content = [for_each_node, if_node, comment_node, value_of_node, tag_node, text_node].join ''

      expected_types = [:for_each, :if, :value_of, :tag, :text]
      expected_classes = [ReverseXSLT::Token::ForEachToken, ReverseXSLT::Token::IfToken,
        ReverseXSLT::Token::ValueOfToken, ReverseXSLT::Token::TagToken, ReverseXSLT::Token::TextToken ]

      doc = Nokogiri::XML(xml % ('<div>%s</div>' % content))

      res = ReverseXSLT::parse_node(doc.root.children.first).children

      res.each_with_index do |item, i|
        expect(item).to be_a(expected_classes[i])
        expect(item.type).to eq(expected_types[i])
        expect(item.children).to be_empty
      end
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
