defmodule SaseMango.SaseScraper do
  @moduledoc false

  alias SaseMango.SaseMangoClient

  @type date :: String.t()
  @type semi_annual :: boolean()
  @type symbol :: String.t()
  @type year :: integer()

  @relevant_segments MapSet.new([
                       "The Official market - The Official market of companies",
                       "The Official market - The Official market of funds",
                       "Free market - Subsegment 1",
                       "Free market - Subsegment 2",
                       "Free market - Subsegment 3"
                     ])

  @spec get_list(date()) :: {:ok, [map()]} | {:error, any()}
  def get_list(date) do
    with {:ok, %Finch.Response{body: body, status: 200}} <- SaseMangoClient.get_list(date),
         {:ok, issuers} <- Jason.decode(body) do
      issuers = Enum.filter(issuers, &MapSet.member?(@relevant_segments, &1["Segment"]))

      {:ok, issuers}
    else
      error ->
        {:error, error}
    end
  end

  @spec get_financial_statement(symbol(), year(), semi_annual()) :: {:ok, map()} | {:error, any()}
  def get_financial_statement(symbol, year, semi_annual) do
    with {:ok, %Finch.Response{body: body, status: 200}} <-
           SaseMangoClient.get_financial_statement(symbol, year, semi_annual),
         data when is_map(data) <- XmlToMap.naive_map(body),
         data <- check_data(data) do
      {:ok, data}
    else
      error ->
        {:error, error}
    end
  end

  defp check_data(data) do
    with [key] <- Map.keys(data),
         %{^key => data} <- data,
         # Discard statements containing only GENERALINFO
         keys when length(keys) > 1 <- Map.keys(data) do
      data
    else
      error ->
        {:error, error}
    end
  end

  @spec get_company_data(symbol()) :: {:ok, map()}
  def get_company_data(symbol) do
    with {:ok, %Finch.Response{body: body, status: 200}} <-
           SaseMangoClient.get_general_data(symbol),
         data when is_map(data) <- XmlToMap.naive_map(body),
         [key] <- Map.keys(data),
         %{^key => symbol_info_data} <- data do
      {:ok, symbol_info_data["GENERALINFO"]}
    else
      _reason ->
        # Some issuers don't have company info data
        {:ok, %{}}
    end
  end

  @spec get_company_owners(symbol()) :: {:ok, map()}
  def get_company_owners(symbol) do
    with {:ok, %Finch.Response{body: body, status: 200}} <-
           SaseMangoClient.get_top_10_owners(symbol),
         data when is_map(data) <- XmlToMap.naive_map(body),
         [key] <- Map.keys(data),
         %{^key => owners_data} <- data do
      {:ok, %{"top_10" => owners_data["Top10"]}}
    end
  end

  @spec get_ticker(symbol()) :: {:ok, map()} | {:error, any()}
  def get_ticker(symbol) do
    with {:ok, %Finch.Response{body: body, status: 200}} <-
           SaseMangoClient.get_ticker(symbol),
         data when is_map(data) <- XmlToMap.naive_map(body),
         [key] <- Map.keys(data),
         %{^key => data} <- data do
      {:ok, data}
    else
      error ->
        {:error, error}
    end
  end
end
