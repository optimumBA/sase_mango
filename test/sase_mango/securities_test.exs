defmodule SaseMango.SecuritiesTest do
  require Logger

  use SaseMango.DataCase, async: true

  alias SaseMango.SaseScraper
  alias SaseMango.Securities
  alias SaseMango.SecuritiesHelper
  alias SaseMango.SecuritiesUpdater
  alias SaseMango.Securities.Issuer
  alias SaseMango.TickerUpdater

  defp test_setup(_attrs) do
    date = SecuritiesHelper.format_date()
    create_or_update(date)

    %{}
  end

  describe "test securities context" do
    setup [:test_setup]

    test "list_issuers/0 returns list of all issuers" do
      refute Enum.empty?(Securities.list_issuers())
      assert Enum.count(Securities.list_issuers()) == 5
    end

    test "get_issuer/1 returns the issuer with given symbol" do
      random_issuer = Securities.list_issuers() |> List.first()
      assert %Issuer{} = issuer = Securities.get_issuer(random_issuer.symbol)

      assert issuer.info == random_issuer.info
      assert issuer.company_data == random_issuer.company_data
    end

    test "get_company_data/1 returns nil for wrong issuer symbol" do
      assert nil == Securities.get_company_data("4444333")
    end

    test "get_company_data/1 returns the company data for given issuer symbol" do
      random_issuer = Securities.list_issuers() |> List.first()

      company_data = Securities.get_company_data(random_issuer.symbol)

      assert company_data.symbol == random_issuer.symbol
      assert company_data.symbol_data.isin == random_issuer.info["ISIN"]
      assert company_data.symbol_data.address == random_issuer.company_data["Address"]
      assert company_data.symbol_data.company == random_issuer.company_data["Company"]
      assert company_data.symbol_data.email == random_issuer.company_data["Email"]

      assert company_data.symbol_data.short_name ==
               random_issuer.company_data["RegistrationNumber"]

      assert company_data.top_10_owners == random_issuer.top_10_owners["top_10"]

      supervisory_board = company_data.supervisory_board

      if is_list(supervisory_board) && Enum.count(supervisory_board) > 0 do
        {name, position} = _first_member = List.first(supervisory_board)
        assert String.contains?(random_issuer.company_data["SupervisoryBoard"], name)
        assert String.contains?(random_issuer.company_data["SupervisoryBoard"], position)
      end

      management_board = company_data.management_board

      if is_list(management_board) && Enum.count(management_board) > 0 do
        {name, position} = _first_member = List.first(management_board)
        assert String.contains?(random_issuer.company_data["ManagementBoard"], name)
        assert String.contains?(random_issuer.company_data["ManagementBoard"], position)
      end
    end
  end

  describe "test issuers data text parsing" do
    test "filter_management_and_supervisory_board/1" do
      first_data_example =
        "Vojko Kokoravec,predsjednik,Dragan Radusinović,član,Radovan Teslić,član do 25.12.2014., Mitar Kovačević,član od 25.12.2014."

      first_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(first_data_example)

      assert Enum.count(first_data_list) == 4
      assert {"Vojko Kokoravec", "predsjednik"} = List.first(first_data_list)
      assert {"Mitar Kovačević", "član od 25.12.2014."} = List.last(first_data_list)

      second_data_example =
        "Mugdim Mandžuka,v.d. predsjednik,Almina Pilav,v.d. član,Nedin Dedić,v.d. član,Haris Delizaimović,v.d. član,Fuad Cuplov,v.d. član,Zoran Marijanović,v.d. član"

      second_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(second_data_example)

      assert Enum.count(second_data_list) == 6
      assert {"Haris Delizaimović", "v.d. član"} = Enum.at(second_data_list, 3)

      third_data_example = "Mujo Selimović,predsjednik,LJiljana Buda,Midhat Hodžić,član"

      third_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(third_data_example)

      assert Enum.count(third_data_list) == 3
      assert {"Mujo Selimović", "predsjednik"} = List.first(third_data_list)
      assert {"LJiljana Buda", ""} = Enum.at(third_data_list, 1)
      assert {"Midhat Hodžić", "član"} = List.last(third_data_list)

      fourth_data_example = "Fadil Mandal, ,Amina Hot, ,Toskić Amer"

      fourth_data_list =
        SecuritiesHelper.filter_management_and_supervisory_data(fourth_data_example)

      assert Enum.count(fourth_data_list) == 3
      assert {"Fadil Mandal", ""} = Enum.at(fourth_data_list, 0)
      assert {"Amina Hot", ""} = Enum.at(fourth_data_list, 1)
      assert {"Toskić Amer", ""} = Enum.at(fourth_data_list, 2)
    end
  end

  defp create_or_update(date) when is_binary(date) do
    case SaseScraper.get_list(date) do
      {:ok, issuers} ->
        Enum.each(Enum.slice(issuers, 0..4), fn issuer ->
          with {symbol, info} <- Map.pop(issuer, "Symbol"),
               {:ok, company_data} <- SaseScraper.get_company_data(symbol),
               {:ok, top_10_owners} <- SaseScraper.get_company_owners(String.slice(symbol, 0..3)),
               issuer_attrs <-
                 SecuritiesUpdater.get_issuers_attrs(company_data, info, symbol, top_10_owners) do
            {:ok, issuer} = SecuritiesUpdater.create_or_update_issuer(symbol, issuer_attrs)
            # current_year = Map.fetch!(NaiveDateTime.utc_now(), :year)

            # for semi_annual <- [true, false], year <- (current_year - 3)..current_year do
            #   SecuritiesUpdater.maybe_create_financial_statement(issuer, semi_annual, year)
            # end
          end
        end)

        TickerUpdater.update()

      _ ->
        nil
    end
  end
end
