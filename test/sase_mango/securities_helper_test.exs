defmodule SaseMango.SecuritiesHelperTest do
  use SaseMango.DataCase, async: true

  alias SaseMango.SecuritiesHelper

  describe "issuers data text parsing test" do
    test "filter_management_and_supervisory_board/1 returns an empty list" do
      assert [] = SecuritiesHelper.filter_management_and_supervisory_data(nil)
    end

    test "filter_management_and_supervisory_board/1 returns a list of tuples" do
      first_data_example =
        "Vojko Kokoravec,predsjednik,Dragan Radusinović,član,Radovan Teslić,član do 25.12.2014., Mitar Kovačević,član od 25.12.2014."

      first_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(first_data_example)

      assert Enum.count(first_data_list) == 4
      assert {"predsjednik", "Vojko Kokoravec"} = List.first(first_data_list)
      assert {"član od 25.12.2014.", "Mitar Kovačević"} = List.last(first_data_list)

      second_data_example =
        "Mugdim Mandžuka,v.d. predsjednik,Almina Pilav,v.d. član,Nedin Dedić,v.d. član,Haris Delizaimović,v.d. član,Fuad Cuplov,v.d. član,Zoran Marijanović,v.d. član"

      second_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(second_data_example)

      assert Enum.count(second_data_list) == 6
      assert {"v.d. član", "Haris Delizaimović"} = Enum.at(second_data_list, 3)

      third_data_example = "Mujo Selimović,predsjednik,LJiljana Buda,Midhat Hodžić,član"

      third_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(third_data_example)

      assert Enum.count(third_data_list) == 3
      assert {"predsjednik", "Mujo Selimović"} = List.first(third_data_list)
      assert {"", "LJiljana Buda"} = Enum.at(third_data_list, 1)
      assert {"član", "Midhat Hodžić"} = List.last(third_data_list)

      fourth_data_example = "Fadil Mandal, ,Amina Hot, ,Toskić Amer"

      fourth_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(fourth_data_example)

      assert Enum.count(fourth_data_list) == 3
      assert {"", "Fadil Mandal"} = Enum.at(fourth_data_list, 0)
      assert {"", "Amina Hot"} = Enum.at(fourth_data_list, 1)
      assert {"", "Toskić Amer"} = Enum.at(fourth_data_list, 2)
    end

    test "parse_shares_and_nominal_price/1 returns an empty list" do
      assert [] = SecuritiesHelper.parse_shares_and_nominal_price(nil)
    end

    test "parse_shares_and_nominal_price/1 " do
      data_payload_1 = "<a href='BHTSR'>BHTSR</a> - 63.457.358 - 10,00 KM |"

      [{symbol, shares, nominal_price}] =
        SecuritiesHelper.parse_shares_and_nominal_price(data_payload_1)

      assert symbol == "BHTSR"
      assert shares == "63.457.358"
      assert nominal_price == "10,00 KM"

      data_payload_2 =
        "<a href='BSNLR'>BSNLR</a> - 8.596.256 - 10,00 KM | <a href='BSNLZ'>BSNLZ</a> - 441.431 - 10,00 KM |"

      [record_1, record_2] = SecuritiesHelper.parse_shares_and_nominal_price(data_payload_2)

      {symbol_1, shares_1, nominal_price_1} = record_1
      {symbol_2, shares_2, nominal_price_2} = record_2

      assert symbol_1 == "BSNLR"
      assert shares_1 == "8.596.256"
      assert nominal_price_1 == "10,00 KM"

      assert symbol_2 == "BSNLZ"
      assert shares_2 == "441.431"
      assert nominal_price_2 == "10,00 KM"
    end
  end
end
