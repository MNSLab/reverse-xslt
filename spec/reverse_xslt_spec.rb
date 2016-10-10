require 'spec_helper'
require 'token_helper'

describe ReverseXSLT do
  include TokenHelper
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

    it 'parse documents without defined namespace' do
      content = [for_each_node, if_node, comment_node, value_of_node, tag_node, text_node].join ''
      doc_1 = ReverseXSLT::parse(Nokogiri::XML(xml % content).children)
      doc_2 = ReverseXSLT::parse(content)

      expect(doc_1).to eq(doc_2)
    end
  end

  describe '.parse(doc)' do
    it 'accepts nokogiri::XML as doc' do
      doc = Nokogiri::XML('<div></div>')

      res = ReverseXSLT::parse(doc)
      expect(res).to be_a(Array)
      expect(res.length).to eq(1)
      expect(res.first).to be_a(ReverseXSLT::Token::TagToken)
    end

    it 'accepts String as doc' do
      res = ReverseXSLT::parse('<div></div>')

      expect(res).to be_a(Array)
      expect(res.length).to eq(1)
      expect(res.first).to be_a(ReverseXSLT::Token::TagToken)
    end

    context 'doc has multiply roots' do
      it 'returns list of tokens' do
        results = ReverseXSLT::parse('<a></a><b></b><c></c>')

        expect(results).to be_a(Array)
        expect(results.length).to eq(3)

        ['a', 'b', 'c'].each_with_index do |x,i|
          expect(results[i]).to be_a(ReverseXSLT::Token::TagToken)
          expect(results[i].value).to eq(x)
        end
      end
    end
  end

  describe '::match?(xslt,xml)' do

  end

  describe '::match(xslt, xml)' do
    it 'raises error when xslt or xml has illegal format' do
      tag = tag_token('div')

      expect {
        ReverseXSLT::match(tag, tag)
      }.to raise_error(ReverseXSLT::Error::IllegalMatchUse)

      expect {
        ReverseXSLT::match(tag, [tag])
      }.to raise_error(ReverseXSLT::Error::IllegalMatchUse)

      expect {
        ReverseXSLT::match([tag], tag)
      }.to raise_error(ReverseXSLT::Error::IllegalMatchUse)

      expect {
        ReverseXSLT::match([tag], [tag])
      }.not_to raise_error
    end
    context 'using value-of-token and text-token' do
      it 'trims whitespaces from text and matching' do
        expect(match([value_of_token('var')], [text_token('     a      b   e     ')])).to eq({'var' => 'a b e'})

        expect(match([text_token('hello world  ')], [text_token("  hello  \n\t\r   world  ")])).to_not be_nil

        expect(match(
          [text_token('    hello  '), value_of_token('var'), text_token('  world  ')],
          [text_token("hello  my       lovely \n\nbeautiful  world")]
        )).to eq({'var' => 'my lovely beautiful'})
      end

      it 'doesn\'t match empty to anything' do
        expect(match([], [])).to_not be_nil
        expect(match([], [text_token('hello')])).to be_nil
        expect(match([], [tag_token('div')])).to be_nil
      end

      it 'match simple value-of to text' do
        doc_1 = [value_of_token('var')]
        doc_2 = [text_token('hello world')]

        res = ReverseXSLT::match(doc_1, doc_2)

        expect(res).to be_a(Hash)
        expect(res['var']).to eq('hello world')
      end

      it 'match value-of+text to text' do
        doc_1 = [value_of_token('var'), text_token('world')]
        doc_2 = [text_token('hello world')]

        res = ReverseXSLT::match(doc_1, doc_2)
        expect(res).to be_a(Hash)
        expect(res['var']).to eq('hello')
      end

      it 'match text+value_of to text' do
        doc_1 = [text_token('hello'), value_of_token('var')]
        doc_2 = [text_token('hello world')]

        res = ReverseXSLT::match(doc_1, doc_2)
        expect(res).to be_a(Hash)
        expect(res['var']).to eq('world')
      end

      it 'match text+value_of+text to text' do
        doc_1 = [text_token('hello'), value_of_token('var'), text_token('world')]
        doc_2 = [text_token('hello beautiful world')]

        res = ReverseXSLT::match(doc_1, doc_2)
        expect(res).to be_a(Hash)
        expect(res['var']).to eq('beautiful')
      end

      it 'match value_of+text+value_of to text' do
        doc_1 = [value_of_token('var_a'), text_token('beautiful'), value_of_token('var_b')]
        doc_2 = [text_token('hello beautiful world')]

        res = ReverseXSLT::match(doc_1, doc_2)
        expect(res).to be_a(Hash)
        expect(res['var_a']).to eq('hello')
        expect(res['var_b']).to eq('world')
      end

      it 'throws error on value-of+value-of to text match' do
        doc_1 = [value_of_token('var_a'), value_of_token('var_b')]
        doc_2 = [text_token('hello world')]

        expect {
          ReverseXSLT::match(doc_1, doc_2)
        }.to raise_error(ReverseXSLT::Error::ConsecutiveValueOfToken)
      end

      it 'throws error on value-of to value-of match' do
        expect {
          ReverseXSLT::match([value_of_token('var_a')], [value_of_token('var_b')])
        }.to raise_error(ReverseXSLT::Error::DisallowedMatch)
      end

      it 'return nil when there is no match' do
        doc_1 = [value_of_token('var'), text_token('hello')]
        doc_2 = [text_token('hello world')]

        expect(ReverseXSLT::match(doc_1, doc_2)).to be_nil

        doc_1[1] = text_token('hello world')
        expect(ReverseXSLT::match(doc_1, doc_2)).to_not be_nil
      end

      it 'return nil when match is not full' do
        doc_1 = [value_of_token('var_a'), text_token('beautiful')]
        doc_2 = [text_token('hello beautiful world')]

        expect(ReverseXSLT::match(doc_1, doc_2)).to be_nil

        doc_1 << value_of_token('var_b')
        expect(ReverseXSLT::match(doc_1, doc_2)).to_not be_nil
      end

      it 'join consecuting text tokens' do
        doc_1 = [text_token('hello world')]
        doc_2 = [text_token('hello'), text_token('world')]

        expect(ReverseXSLT::match(doc_1, doc_2)).to_not be_nil
        expect(ReverseXSLT::match(doc_2, doc_1)).to_not be_nil
      end

      it 'match value-of to text+text' do
        doc_1 = [value_of_token('var')]
        doc_2 = [text_token('hello'), text_token('world')]

        res = ReverseXSLT::match(doc_1, doc_2)
        expect(res).to be_a(Hash)
        expect(res['var']).to eq('hello world')
      end

      it 'allow value-of to match empty string' do
        doc_1 = [text_token('hello'), value_of_token('var'), text_token('world')]
        doc_2 = [text_token('hello world')]

        res = ReverseXSLT::match(doc_1, doc_2)
        expect(res).to be_a(Hash)
        expect(res['var']).to eq('')
      end

      it 'allow value-of+value-of matching when additional regexps are defined' do
        doc_1 = [value_of_token('count'), value_of_token('noun')]
        doc_2 = [text_token('127 bits')]

        expect {
          match(doc_1, doc_2)
        }.to raise_error

        expect {
          res = match(doc_1, doc_2, {count: /[0-9]+/})
          expect(res).to eq({'count' => '127', 'noun' => 'bits'})
        }.to_not raise_error
      end

      it 'throws error on duplicated value-of token name' do
        doc_1 = [value_of_token('var'), text_token(":"), value_of_token('var')]
        doc_2 = [text_token("color: blue")]

        expect {
          match(doc_1, doc_2)
        }.to raise_error(ReverseXSLT::Error::DuplicatedTokenName)
      end

      it 'works on real life examples' do
        text_1 = %(
          Ogłoszenie nr
          <xsl:value-of select="//a:pozycja"/>
          -
          <xsl:value-of select="//a:biuletyn"/>
          z dnia
          <xsl:value-of select="//a:data_publikacji"/>
          r.)

        text_2 = %(
          Ogłoszenie nr 319020 - 2016
          z dnia 2016-10-06 r.
        )

        doc_1 = ReverseXSLT::parse(text_1)
        doc_2 = ReverseXSLT::parse(text_2)

        res = ReverseXSLT::match(doc_1, doc_2)

        expect(res).to be_a(Hash)
        expect(res.length).to eq(3)

        expect(res['pozycja']).to eq('319020')
        expect(res['biuletyn']).to eq('2016')
        expect(res['data_publikacji']).to eq('2016-10-06')
      end
    end

    context 'using value-of, text and tag tokens' do
      it 'match tag+value-of+tag to tag+tag' do #empty value-of production
        doc_1 = parse('<div></div><xsl:value-of select="var" /><span></span>')
        doc_2 = parse('<div></div><span></span>')

        expect(match(doc_1, doc_2)).to eq({'var' => ''})
      end

      it 'doesn\'t matched tag to text or value-of' do
        doc_1 = parse('hello beautiful world')
        doc_2 = parse('hello world')
        doc_3 = parse('hello <xsl:value-of select="var"/> wordl')
        doc_4 = parse('hello <beautiful /> world')

        expect(match(doc_1, doc_4)).to be_nil
        expect(match(doc_2, doc_4)).to be_nil
        expect(match(doc_3, doc_4)).to be_nil
      end

      it 'match tag only to tag' do
        doc_1 = [tag_token('div')]
        expect(ReverseXSLT::match(doc_1, [tag_token('div')] )).to be_a(Hash)
        expect(ReverseXSLT::match(doc_1, [tag_token('span')] )).to be_nil
        expect(ReverseXSLT::match(doc_1, [text_token("div")] )).to be_nil
      end

      it 'match tag content recursivly' do
        doc_1 = parse('<div><a>quote of the day: <span><xsl:value-of select="var" /></span></a></div>')
        doc_2 = parse('<div><a>quote of the day: <span>hello world</span></a></div>')

        expect(match(doc_1, doc_2)).to eq({'var' => 'hello world'})
      end

      it 'works with real life examples' do
        xml_1 = %(
          <div>
            Ogłoszenie nr
            <xsl:value-of select="//a:pozycja"/>
            -
            <xsl:value-of select="//a:biuletyn"/>
            z dnia
            <xsl:value-of select="//a:data_publikacji"/>
            r.
          </div>
          <div class="headerMedium_xforms" style="text-align: center">
            <xsl:value-of select="//a:zamawiajacy_miejscowosc"/>
            :
            <xsl:value-of select="//a:nazwa_nadana_zamowieniu"/>
            <br/>
            OGŁOSZENIE O ZAMÓWIENIU -
            <xsl:value-of select="//a:rodzaj_zamowienia"/>
          </div>
        )

        xml_2 = %(
          <div>
            Ogłoszenie nr 319424 - 2016
            z dnia 2016-10-07 r.
          </div><div class="headerMedium_xforms" style="text-align: center">Kraków: Wykonanie robót budowlanych w zakresie bieżącej konserwacji pomieszczeń budynku na os. Krakowiaków 46 w Krakowie<br />
          OGŁOSZENIE O ZAMÓWIENIU -

            Roboty budowlane
          </div>
        )

        res = match(parse(xml_1), parse(xml_2))

        expect(res).to eq({
          'pozycja' => '319424',
          'biuletyn' => '2016',
          'data_publikacji' => '2016-10-07',
          'zamawiajacy_miejscowosc' =>'Kraków',
          'nazwa_nadana_zamowieniu' => 'Wykonanie robót budowlanych w zakresie bieżącej konserwacji pomieszczeń budynku na os. Krakowiaków 46 w Krakowie',
          'rodzaj_zamowienia' => 'Roboty budowlane'
        })
      end

    end

    context 'using if-token' do
      it 'allows to match or not given content' do
        doc_1 = [if_token('var'){[tag_token('div')]}]
        expect(match([], [tag_token('span')])).to be_nil
        expect(match(doc_1, [])).to_not be_nil
        expect(match(doc_1, [tag_token('div')])).to_not be_nil
        expect(match(doc_1, [tag_token('span')])).to be_nil
      end

      it 'does simple matching' do
        doc_1 = [
          text_token('count:'),
          if_token('var'){[value_of_token('count'), text_token('users')]}, text_token('here')
        ]

        expect(match([text_token('count:'), text_token('here')], [text_token('count:   here')])).to_not be_nil
        expect(match(doc_1, [text_token('count:   here')])).to_not be_nil

        expect(match([text_token('count:'), value_of_token('count'), text_token('users'), text_token('here')], [text_token('count: 42   users here')])).to_not be_nil
        expect(match(doc_1, [text_token('count: 42   users here')])).to_not be_nil
      end

      it 'does simple matching and store if-token matching' do
        doc_1 = [
          text_token('count:'),
          if_token('var'){[value_of_token('count'), text_token('users')]}, text_token('here')
        ]
        exp = {
          'var' => '42 users',
          'count' => '42'
        }
        expect(match(doc_1, [text_token('count: 42   users here')])).to eq(exp)
      end

      it 'raise error when match multiple if-token with the same name' do
        doc_1 = [
          if_token('var'){[text_token('red')]},
          tag_token('div'),
          if_token('var'){[text_token('red')]}
        ]

        expect {
          match(doc_1, parse('red<div></div>red'))
        }.to raise_error(ReverseXSLT::Error::DuplicatedTokenName)

        expect {
          match(doc_1, parse('red<div></div>'))
          match(doc_1, parse('<div></div>'))
          match(doc_1, parse('<div></div>red'))
        }.to_not raise_error
      end

      it 'can simulate case statement' do
        doc_1 = [
          text_token('color:'),
          if_token('var'){[text_token('red')]},
          if_token('var'){[text_token('green')]},
          if_token('var'){[text_token('blue')]}
        ]

        expect(match(doc_1, [text_token('color: red')])).to eq({'var' => 'red'})
        expect(match(doc_1, [text_token('color: green')])).to eq({'var' => 'green'})
        expect(match(doc_1, [text_token('color: blue')])).to eq({'var' => 'blue'})
        expect(match(doc_1, [text_token('color: yellow')])).to be_nil
      end

      it 'runs at the same level' do
        doc_1 = [
          if_token('var') { [tag_token('div')] }
        ]
        expect(match(doc_1, [tag_token('div')])).to_not be nil
      end

      it 'simulate POST problem (PCP)'

      it 'works with real life examples' do
        xml_1 = %(
          <div>
            <xsl:if test="(//a:pozycja != '') and (//a:data_publikacji != '') and (//a:biuletyn != '')">
            Ogłoszenie nr
            <xsl:value-of select="//a:pozycja"/>
            -
            <xsl:value-of select="//a:biuletyn"/>
            z dnia
            <xsl:value-of select="//a:data_publikacji"/>
            r.
            </xsl:if>
          </div>
          <div class="headerMedium_xforms" style="text-align: center">
            <xsl:value-of select="//a:zamawiajacy_miejscowosc"/>
            :
            <xsl:value-of select="//a:nazwa_nadana_zamowieniu"/>
            <br/>
            OGŁOSZENIE O ZAMÓWIENIU -
            <xsl:if test="//a:rodzaj_zamowienia = '0'">Roboty budowlane</xsl:if>
            <xsl:if test="//a:rodzaj_zamowienia = '1'">Dostawy</xsl:if>
            <xsl:if test="//a:rodzaj_zamowienia = '2'">Usługi</xsl:if>
          </div>
          <div>
            <b>Zamieszczanie ogłoszenia:</b>
            <xsl:if test="//a:zamieszczanie_obowiazkowe = '1'">obowiązkowe</xsl:if>
            <xsl:if test="//a:zamieszczanie_obowiazkowe != '1'">nieobowiązkowe</xsl:if>
          </div>
        )

        xml_2 = %(
          <div>
            Ogłoszenie nr 319424 - 2016
            z dnia 2016-10-07 r.
          </div><div class="headerMedium_xforms" style="text-align: center">Kraków: Wykonanie robót budowlanych w zakresie bieżącej konserwacji pomieszczeń budynku na os. Krakowiaków 46 w Krakowie<br />
          OGŁOSZENIE O ZAMÓWIENIU -

            Roboty budowlane
          </div><div><b>Zamieszczanie ogłoszenia:</b>
            obowiązkowe
          </div>
        )

        res = match(parse(xml_1), parse(xml_2))

        expect(res).to eq({
          'zamieszczanie_obowiazkowe' => 'obowiązkowe',
          'rodzaj_zamowienia' => 'Roboty budowlane',
          'pozycja' => '319424',
          'biuletyn' => '2016',
          'data_publikacji' => '2016-10-07',
          'zamawiajacy_miejscowosc' =>'Kraków',
          'nazwa_nadana_zamowieniu' => 'Wykonanie robót budowlanych w zakresie bieżącej konserwacji pomieszczeń budynku na os. Krakowiaków 46 w Krakowie',
          "pozycja_data_publikacji_biuletyn" => "Ogłoszenie nr 319424 - 2016 z dnia 2016-10-07 r."
        })
      end
    end

    context 'using for-each-token' do
      it 'match multiple occurence of text-token' do
        pending

        doc_1 = [for_each_token('worlds'){ [text_token('world')]}]
        doc_2 = [text_token('  world  world  world world  world  world  ')]

        res = match(doc_1, doc_2)
        expect(res).to_not be_nil

        expect(res['var']).to be_a(Array)
        expect(res['var'].length).to eq(6)
        (0..5).each do |i|
          expect(res['var'][i]).to eq({})
        end
      end

      it 'match multipe occurence of text and if tokens' do
        pending

        doc_1 = [for_each_token('var'){[
            value_of_token('number'),
            if_token('comma'){[text_token(',')]}
          ]}]

        doc_2 = [text_token('123, 124   , 125,1000')]

        expect {
          match(doc_1, doc_2)
        }.to raise_error

        expect {
          res = match(doc_1, doc_2, {'var' => /[0-9]+/})
        }.to_not raise_error

        expect(res).to be_a(Hash)


        expect(res['var']).to be_a(Array)

        expect(res['var'][0]['number']).to eq('123')
        expect(res['var'][1]['number']).to eq('124')
        expect(res['var'][2]['number']).to eq('125')
        expect(res['var'][3]['number']).to eq('1000')
      end
    end
  end
end
