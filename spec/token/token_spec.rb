require 'spec_helper'

describe ReverseXSLT::Token do

  describe '.tokenize' do
    it 'removes [^_a-z] characters' do
      expect(ReverseXSLT::Token::Token.tokenize('qwertyuiopasdfghjklzxcvbn_m1234567890!@#$%^&*()+-=<>,.?/;:[{}]')).to eq('qwertyuiopasdfghjklzxcvbn_m')
    end

    it 'removes trailing/leading underscores' do
      expect(ReverseXSLT::Token::Token.tokenize('_a_')).to eq('a')
      expect(ReverseXSLT::Token::Token.tokenize('1231____a_b_c___12312')).to eq('a_b_c')
    end

    it 'removes succesing underscores' do
      expect(ReverseXSLT::Token::Token.tokenize('a_1_b_2_3_4_c_5_d')).to eq('a_b_c_d')
    end

    it 'removes namespace prefixes' do
      expect(ReverseXSLT::Token::Token.tokenize('ruby:hello')).to eq('hello')
    end

    it 'removes some meta words' do
      expect(ReverseXSLT::Token::Token.tokenize('not/and/or')).to eq('')
      expect(ReverseXSLT::Token::Token.tokenize('1not2not3')).to eq('')
    end

    it 'doesnt remove meta words from inside others' do
      expect(ReverseXSLT::Token::Token.tokenize('not_or_and')).to eq('not_or_and')
      expect(ReverseXSLT::Token::Token.tokenize('nothing/knot/another')).to eq('nothing_knot_another')
      expect(ReverseXSLT::Token::Token.tokenize('ror/order/pork')).to eq('ror_order_pork')
      expect(ReverseXSLT::Token::Token.tokenize('osmand/anderson/candel')).to eq('osmand_anderson_candel')
    end

    it 'concatenate word with underscore' do
      expect(ReverseXSLT::Token::Token.tokenize('code:languages/ruby/jruby != 2')).to eq('languages_ruby_jruby')
    end

    it 'works with real life examples' do
      examples = {
        '' => '',
        "//a:czy_przeprowadza_wapolnie = '1'" => 'czy_przeprowadza_wapolnie',
        'position() != last()' => 'position_last',
        '//a:cpv_glowny_przedmiot/a:cpv[not(../../../.. != '')]' => 'cpv_glowny_przedmiot_cpv',
        'not/a/b' => 'a_b', 'a/not/b' => 'a_b', 'a/b/not' => 'a_b',
        "(//a:tryb_udzielenia_zamowienia != '7') and (//a:czy_dopuszcza_sie_zlozenie_oferty_czesciowej !!= '1')" => 'tryb_udzielenia_zamowienia_czy_dopuszcza_sie_zlozenie_oferty_czesciowej',
        "//a:zalaczniki/a:zalacznik/a:zalacznik_czesc_nr != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_nazwa != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_opis != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_cpv_glowny_przedmiot/a:cpv/a:value != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_cpv_dodatkowe_przedmioty/a:cpv/a:value != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_okres_w_miesiacach != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_okres_w_dniach != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_data_rozpoczecia != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_data_zakonczenia != '' or //a:zalaczniki/a:zalacznik/a:zalacznik_kryteria_oceny_ofert != ''" => 'zalaczniki_zalacznik_zalacznik_czesc_nr_zalaczniki_zalacznik_zalacznik_nazwa_zalaczniki_zalacznik_zalacznik_opis_zalaczniki_zalacznik_zalacznik_cpv_glowny_przedmiot_cpv_value_zalaczniki_zalacznik_zalacznik_cpv_dodatkowe_przedmioty_cpv_value_zalaczniki_zalacznik_zalacznik_okres_w_miesiacach_zalaczniki_zalacznik_zalacznik_okres_w_dniach_zalaczniki_zalacznik_zalacznik_data_rozpoczecia_zalaczniki_zalacznik_zalacznik_data_zakonczenia_zalaczniki_zalacznik_zalacznik_kryteria_oceny_ofert'
      }

      examples.each do |k,v|
        expect(ReverseXSLT::Token::Token.tokenize(k)).to eq(v)
      end
    end


  end
end
