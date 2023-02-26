defmodule SaseMangoWeb.SecuritiesLiveTest do
  use ExUnit.Case
  use SaseMangoWeb.ConnCase

  import Phoenix.LiveViewTest

  alias SaseMango.SaseScraper
  alias SaseMango.Securities
  alias SaseMango.SecuritiesHelper
  alias SaseMango.SecuritiesUpdater
  alias SaseMango.TickerUpdater

  defp test_setup(_attrs) do
    date = SecuritiesHelper.format_date()
    create_or_update(date)

    _securities_cache = start_supervised!(SaseMango.SecuritiesCache)
    _bargains_cache = start_supervised!(SaseMango.BargainsCache)

    %{}
  end

  describe "test securities_live" do
    setup [:test_setup]

    test "show list of securities and open company info page", %{
      conn: conn
    } do
      {:ok, securities_live, html} = live(conn, Routes.securities_index_path(conn, :securities))

      assert html =~ SecuritiesHelper.format_date()
      assert html =~ "List of securities"
      assert html =~ "Bargain securities"
      assert html =~ "Calculator"

      assert has_element?(securities_live, ".securities-table")

      assert securities_cache_list = SaseMango.SecuritiesCache.get()
      refute Enum.empty?(securities_cache_list)

      for security <- securities_cache_list do
        assert html =~ security.symbol
        assert html =~ security.name
        assert html =~ Securities.segment(security.segment)
      end

      random_issuer = Securities.list_issuers() |> List.first()
      company_data = Securities.get_company_data(random_issuer.symbol)

      {:ok, _company_info_live, html} =
        live(conn, Routes.securities_show_path(conn, :index, random_issuer.symbol))

      assert html =~ "Issuer profile"
      assert html =~ company_data.name
      assert html =~ company_data.symbol_data.isin
      assert html =~ company_data.symbol_data.address
      assert html =~ company_data.symbol_data.short_name

      supervisory_board = company_data.supervisory_board

      if is_list(supervisory_board) && !Enum.empty?(supervisory_board) do
        for {person, position} <- supervisory_board do
          assert html =~ person
          assert html =~ position
        end
      end

      management_board = company_data.management_board

      if is_list(management_board) && !Enum.empty?(management_board) do
        for {person, position} <- management_board do
          assert html =~ person
          assert html =~ position
        end
      end

      for {owner, position} <- company_data.top_10_owners do
        assert html =~ owner
        assert html =~ position
      end
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
                 SecuritiesUpdater.get_issuers_attrs(company_data, info, symbol, top_10_owners),
               {:ok, issuer} <- SecuritiesUpdater.create_or_update_issuer(symbol, issuer_attrs) do
            current_year = Map.fetch!(NaiveDateTime.utc_now(), :year)

            for semi_annual <- [true, false], year <- (current_year - 3)..current_year do
              SecuritiesUpdater.maybe_create_financial_statement(issuer, semi_annual, year)
            end
          end
        end)

        TickerUpdater.update()

      _ ->
        nil
    end
  end
end
