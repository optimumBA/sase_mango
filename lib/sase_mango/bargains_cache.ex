defmodule SaseMango.BargainsCache do
  use GenServer

  alias SaseMango.Securities
  alias SaseMangoWeb.Endpoint

  defstruct executed_at: nil,
            today_bargains: [],
            yesterday_bargains: []

  # Client side API

  def start_link(_opts) do
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
    {:noreply, fetch_bargains(state)}
  end

  @impl GenServer
  def handle_call(:get, _from, %__MODULE__{today_bargains: bargains_list} = state) do
    {:reply, bargains_list, state}
  end

  @impl GenServer
  def handle_cast(:update, %__MODULE__{} = state) do
    state = fetch_bargains(state)

    Endpoint.broadcast("securities", "securities_update", %{})

    {:noreply, state}
  end

  defp fetch_bargains(%__MODULE__{} = state) do
    state = maybe_move_to_yesterday_list(state)

    new_list =
      Securities.list_securities(:bargains)
      |> Enum.reduce([], fn %{} = security, new_list ->
        new =
          !Enum.find(state.yesterday_bargains, fn %{} = old_security ->
            old_security.symbol == security.symbol
          end)

        security = Map.put(security, :new, new)

        newest =
          !Enum.find(state.today_bargains, fn %{} = old_security ->
            old_security.symbol == security.symbol
          end)

        security = Map.put(security, :newest, newest)

        [security | new_list]
      end)

    state
    |> Map.put(:executed_at, DateTime.utc_now())
    |> Map.put(:today_bargains, new_list)
  end

  defp maybe_move_to_yesterday_list(state) do
    today_date = DateTime.to_date(DateTime.utc_now())

    with %DateTime{} = executed_at <- state.executed_at,
         date_of_execution <- DateTime.to_date(executed_at),
         :gt <- Date.compare(today_date, date_of_execution) do
      Map.put(state, :yesterday_bargains, state.today_bargains)
    else
      _ ->
        state
    end
  end
end
