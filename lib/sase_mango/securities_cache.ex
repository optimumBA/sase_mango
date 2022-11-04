defmodule SaseMango.SecuritiesCache do
  use GenServer

  alias SaseMango.Securities
  alias SaseMangoWeb.Endpoint

  @table :securities
  @key :list

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
    case :ets.lookup(@table, @key) do
      [{_key, securities}] ->
        securities

      _ ->
        []
    end
  end

  def update_securities() do
    GenServer.cast(__MODULE__, :update_securities)
  end

  # Server side callbacks

  @impl true
  def init(_opts) do
    :ets.new(@table, [:named_table, :set, read_concurrency: true])

    {:ok, []}
  end

  @impl true
  def handle_cast(:update_securities, _state) do
    securities = Securities.list_securities(:securities)

    :ets.delete(@table, @key)
    :ets.insert(@table, {@key, securities})

    Endpoint.broadcast("securities", "securities_update", %{})

    {:noreply, []}
  end
end
