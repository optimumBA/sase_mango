defmodule SaseMango.SecuritiesCache do
  use GenServer

  alias SaseMango.Securities
  alias SaseMangoWeb.Endpoint

  defstruct securities_list: []

  # Client side API

  def start_link(_attrs) do
    case GenServer.start_link(__MODULE__, :ok, name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  def get_securities() do
    GenServer.call(__MODULE__, :get_securities)
  end

  def update_securities() do
    GenServer.cast(__MODULE__, :update_securities)
  end

  # Server side callbacks

  @impl true
  def init(_opts) do
    {:ok, %__MODULE__{}}
  end

  @impl true
  def handle_call(:get_securities, _from, %__MODULE__{securities_list: list} = state) do
    {:reply, list, state, :hibernate}
  end

  @impl true
  def handle_cast(:update_securities, %__MODULE__{} = state) do
    state = Map.put(state, :securities_list, Securities.list_securities(:securities))

    Endpoint.broadcast("securities", "securities_update", %{})

    {:noreply, state, :hibernate}
  end
end
