defmodule Mix.Tasks.Issuers.Fetch do
  use Mix.Task

  alias SaseMango.{Issuers, SaseScraper}

  @requirements ["app.start"]

  @impl Mix.Task
  def run([date]) do
    {:ok, issuers} = SaseScraper.get_list(date)

    Enum.each(issuers, fn issuer ->
      with {symbol, info} <- Map.pop(issuer, "Symbol"),
           {:ok, issuer} <- Issuers.create_issuer(%{info: info, symbol: symbol}) do
        for semi_annual <- [true, false], year <- 2015..2020 do
          {:ok, statement} = SaseScraper.get_financial_statement(symbol, year, semi_annual)

          {:ok, _financial_statement} =
            Issuers.create_financial_statement(issuer, %{
              statement: statement,
              semi_annual: semi_annual,
              year: year
            })
        end
      end
    end)
  end
end
