defmodule Mix.Tasks.InvestBa.CreatePost do
  use Mix.Task

  require Logger

  alias SaseMango.{InvestBaPostCreator, PlainTextTableRenderer, Securities, SecuritiesUpdater}
  alias SaseMangoWeb.SecuritiesView

  @requirements ["app.start"]

  @impl Mix.Task
  def run(_) do
    case SecuritiesUpdater.update() do
      {:ok, [_ | _]} ->
        rows =
          Securities.list_securities()
          |> Enum.map(fn security ->
            [
              [
                issuer: security.symbol,
                ask: SecuritiesView.format_number(security.ask_price, 2),
                bid: SecuritiesView.format_number(security.bid_price, 2),
                dividend_roi: SecuritiesView.format_percentage(security.dividend_roi),
                eps_roi: SecuritiesView.format_percentage(security.eps_roi),
                book_value: SecuritiesView.format_number(security.book_value, 0),
                bvs: SecuritiesView.format_number(security.bvs, 2),
                profit_margin: SecuritiesView.format_percentage(security.profit_margin)
              ],
              [
                issuer: security.name,
                price: SecuritiesView.format_number(security.price, 2),
                nominal_price: SecuritiesView.format_number(security.nominal_price, 2),
                pe: SecuritiesView.format_number(security.pe, 2),
                pb: SecuritiesView.format_number(security.pb, 2),
                market_value: SecuritiesView.format_number(security.market_value, 0)
              ],
              [
                issuer: SecuritiesView.segment(security.segment),
                ask: SecuritiesView.format_number(security.ask_volume),
                bid: SecuritiesView.format_number(security.bid_volume),
                dividend_roi: SecuritiesView.format_percentage(security.previous_dividend_roi),
                eps_roi: SecuritiesView.format_percentage(security.previous_eps_roi),
                book_value: SecuritiesView.format_number(security.previous_book_value, 0),
                bvs: SecuritiesView.format_number(security.previous_bvs, 2),
                profit_margin: SecuritiesView.format_percentage(security.previous_profit_margin)
              ]
            ]
          end)

        table =
          [
            header: [
              issuer: "Issuer",
              price: "Price",
              nominal_price: "Nominal price",
              ask: "Ask",
              bid: "Bid",
              dividend_roi: "Dividend ROI",
              eps_roi: "EPS ROI",
              pe: "P/E",
              pb: "P/B",
              market_value: "Market Value",
              book_value: "Book Value",
              bvs: "BVS",
              profit_margin: "Profit margin"
            ],
            rows: rows
          ]
          |> PlainTextTableRenderer.render()

        InvestBaPostCreator.post("[code]#{table}[/code]")

      _ ->
        nil
    end
  end
end
