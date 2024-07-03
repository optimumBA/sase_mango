defmodule SaseMango.SecuritiesCache do
  @moduledoc false

  use GenServer

  alias SaseMango.Securities
  alias SaseMangoWeb.Endpoint

  @table :securities
  @key :list

  # Client side API

  @spec start_link(any()) :: {:ok, pid()} | :ignore
  def start_link(_attrs) do
    case GenServer.start_link(__MODULE__, :ok, name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  @spec get() :: list()
  def get do
    case :ets.lookup(@table, @key) do
      [{_key, securities}] ->
        securities

      _other ->
        []
    end
  end

  @spec update() :: :ok
  def update do
    GenServer.cast(__MODULE__, :update)
  end

  # Server side callbacks

  @impl GenServer
  def init(_opts) do
    {:ok, [], {:continue, :init_cache}}
  end

  @impl GenServer
  def handle_continue(:init_cache, _state) do
    :ets.new(@table, [:named_table, :set, read_concurrency: true])
    update_cache()

    {:noreply, []}
  end

  @impl GenServer
  def handle_cast(:update, _state) do
    update_cache()

    Endpoint.broadcast("securities", "securities_update", %{})

    {:noreply, []}
  end

  defp update_cache do
    securities =
      :securities
      |> Securities.list_securities()
      |> Enum.to_list()

    :ets.delete(@table, @key)
    :ets.insert(@table, {@key, securities})
  end
end
