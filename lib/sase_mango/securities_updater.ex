defmodule SaseMango.SecuritiesUpdater do
  use GenServer

  alias SaseMango.{SaseScraper, Securities}
  alias SaseMangoWeb.Endpoint

  @interval 5 * 60 * 1000
  @opening_time ~T[10:00:00]
  @closing_time ~T[13:30:00]
  @workdays 1..5
  @timezone "Europe/Sarajevo"

  # Client

  def start_link(_) do
    case GenServer.start_link(__MODULE__, :ok, name: __MODULE__) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, {:already_started, _pid}} ->
        :ignore
    end
  end

  # Server

  @impl true
  def init(:ok) do
    schedule_updating()
    {:ok, nil}
  end

  @impl true
  def handle_info(:update, _state) do
    update()
    schedule_updating()
    {:noreply, nil}
  end

  defp update() do
    issuers = Securities.list_issuers()

    for %Securities.Issuer{} = issuer <- issuers do
      case SaseScraper.get_ticker(issuer.symbol) do
        {:ok, %{"pr_issuer_details" => %{"OfficialBestAskPrice" => ask_price}}} ->
          ask_price = String.to_float(ask_price)
          info = issuer.info |> Map.put("BestAskPrice", ask_price)
          Securities.update_issuer(issuer, %{info: info})

        _ ->
          nil
      end
    end

    Endpoint.broadcast("securities", "securities_update", %{})
  end

  defp schedule_updating() do
    datetime = DateTime.now!(@timezone)
    day_of_week = datetime |> DateTime.to_date() |> Date.day_of_week()
    time = datetime |> DateTime.to_time()

    if Time.compare(time, @opening_time) != :lt && Time.compare(time, @closing_time) != :gt &&
         Enum.member?(@workdays, day_of_week) do
      Process.send_after(self(), :update, @interval)
    else
      day =
        cond do
          Enum.member?(@workdays, day_of_week) && Time.compare(time, @opening_time) == :lt ->
            datetime

          Enum.member?(5..6, day_of_week) ->
            datetime |> DateTime.add((8 - day_of_week) * 24 * 60 * 60, :second)

          true ->
            datetime |> DateTime.add(24 * 60 * 60, :second)
        end

      opening_date = day |> DateTime.to_date() |> Date.to_iso8601()
      opening_time = @opening_time |> Time.to_iso8601()
      offset = datetime |> DateTime.to_iso8601() |> String.slice(19..-1)

      {:ok, opening_datetime, _utc_offset} =
        DateTime.from_iso8601("#{opening_date}T#{opening_time}#{offset}")

      diff = DateTime.diff(opening_datetime, datetime)

      Process.send_after(self(), :update, diff * 1000)
    end
  end
end
