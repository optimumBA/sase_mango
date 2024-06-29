defmodule SaseMango.InvestorsCache do
  use GenServer

  alias SaseMango.Securities
  alias SaseMango.SecuritiesHelper
  alias SaseMangoWeb.Endpoint

  defstruct investors_list: []

  # Client side API

  def start_link(_attrs) do
    case GenServer.start_link(__MODULE__, :ok, name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def get(limit) do
    GenServer.call(__MODULE__, {:get, limit})
  end

  def filter_investor_list(term) when is_binary(term) do
    GenServer.call(__MODULE__, {:filter, term})
  end

  def get_investor(investor_name) when is_binary(investor_name) do
    GenServer.call(__MODULE__, {:get_investor, investor_name})
  end

  def update() do
    GenServer.cast(__MODULE__, :update)
  end

  # Server side callbacks

  @impl GenServer
  def init(_opts) do
    {:ok, %__MODULE__{}, {:continue, :init_cache}}
  end

  @impl GenServer
  def handle_continue(:init_cache, %__MODULE__{} = state) do
    {:noreply, update_cache(state)}
  end

  @impl GenServer
  def handle_call(:get, _from, %__MODULE__{investors_list: investors_list} = state) do
    {:reply, investors_list, state}
  end

  def handle_call({:get, limit}, _from, %__MODULE__{investors_list: investors_list} = state) do
    paginated_list = Enum.slice(investors_list, 0, limit)

    {:reply, paginated_list, state}
  end

  def handle_call({:filter, term}, _from, %__MODULE__{investors_list: investors_list} = state) do
    filtered_list = Enum.filter(investors_list, &String.contains?(String.downcase(&1.name), term))

    {:reply, filtered_list, state}
  end

  def handle_call(
        {:get_investor, investor_name},
        _from,
        %__MODULE__{investors_list: investors_list} = state
      ) do
    investor = Enum.find(investors_list, &(&1.name_slug == investor_name))
    investor_issuers = fetch_issuers_list(Map.get(investor, :issuers))

    {:reply,
     %{
       name: investor.name,
       name_slug: investor.name_slug,
       issuers_list: investor_issuers
     }, state}
  end

  @impl GenServer
  def handle_cast(:update, %__MODULE__{} = state) do
    state = update_cache(state)

    Endpoint.broadcast("investors", "investors_update", %{})

    {:noreply, state}
  end

  defp update_cache(%__MODULE__{} = state) do
    Map.put(state, :investors_list, Securities.list_investors())
  end

  defp fetch_issuers_list(investor_issuers) do
    investor_issuers
    |> Enum.reduce([], fn %{issuer: issuer, shares_number: shares_number}, issuers_list ->
      issuer_data = %{
        symbol: issuer.symbol,
        name: issuer.info["SymbolDescription"],
        investor_shares_number: shares_number,
        price: SecuritiesHelper.convert_number_to_decimal(issuer.info["AvgPrice"])
      }

      [issuer_data | issuers_list]
    end)
  end
end
