defmodule SaseMango.SecuritiesCache do
  use GenServer

  alias SaseMango.Securities
  alias SaseMangoWeb.Endpoint

  defstruct executed_at: nil,
            today: [],
            yesterday: []

  # Client

  def start_link(_) do
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

  # Server

  @impl true
  def init(:ok) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(:get, _from, %__MODULE__{today: list} = state) do
    {:reply, list, state, :hibernate}
  end

  @impl true
  def handle_cast(:update, %__MODULE__{} = state) do
    state =
      with executed_at when not is_nil(executed_at) <- state.executed_at,
           date_of_execution <- DateTime.to_date(executed_at),
           today <- DateTime.utc_now() |> DateTime.to_date(),
           :gt <- Date.compare(today, date_of_execution) do
        Map.put(state, :yesterday, state.today)
      else
        _ ->
          state
      end

    {list, newest_securities} =
      Securities.list_securities()
      |> Enum.map_reduce([], fn %{} = security, newest_securities ->
        new =
          !Enum.find(state.yesterday, fn %{} = old_security ->
            old_security.symbol == security.symbol
          end)

        security = Map.put(security, :new, new)

        newest =
          !Enum.find(state.today, fn %{} = old_security ->
            old_security.symbol == security.symbol
          end)

        security = Map.put(security, :newest, newest)

        newest_securities =
          if newest do
            [security.symbol | newest_securities]
          else
            newest_securities
          end

        {security, newest_securities}
      end)

    state =
      state
      |> Map.put(:executed_at, DateTime.utc_now())
      |> Map.put(:today, list)

    Endpoint.broadcast("securities", "securities_update", %{})

    unless Enum.empty?(newest_securities) do
      body = "New securities: " <> Enum.join(newest_securities, ", ")
      Endpoint.broadcast("securities", "send_notification", %{body: body})
    end

    {:noreply, state, :hibernate}
  end
end
