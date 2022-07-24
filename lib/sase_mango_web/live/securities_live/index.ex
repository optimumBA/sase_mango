defmodule SaseMangoWeb.SecuritiesLive.Index do
  use SaseMangoWeb, :live_view

  alias SaseMango.Securities
  # alias SaseMango.HandleTable
  # alias SaseMango.HandleTable.SearchFilter
  # alias SaseMangoWeb.Components.FilterFormComponent
  # alias SaseMangoWeb.Components.SortingComponent
  alias SaseMangoWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign_new(socket, :securities, fn ->
        list_securities()
      end)

    if connected?(socket) do
      Endpoint.subscribe("securities")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, assign_params(socket, params)}
  end

  defp assign_params(socket, params) do
    socket
    |> assign(:active_tab, active_tab(socket.assigns.live_action))
    # |> assign(:filter_options, %SearchFilter{name: params["name"] || nil})
    |> apply_action(socket.assigns.live_action, params)
  end

  defp apply_action(socket, :securities, _params) do
    socket
    |> assign(:page_title, "List of securities")
    |> assign(:securities, [])

    # |> assign(:sort_options, %{sort_by: nil, sort_order: nil})
  end

  defp apply_action(socket, :bargains, _params) do
    socket
    |> assign(:page_title, "List of bargain securities")
    |> assign(:securities, list_securities())

    # |> assign(:sort_options, %{sort_by: nil, sort_order: nil})
  end

  @impl true
  def handle_info(%Broadcast{event: "securities_update"}, socket) do
    {:noreply, assign(socket, :securities, list_securities())}
  end

  defp list_securities(), do: Securities.list_securities()

  defp active_tab(action) when action in [:securities, :bargains], do: action
  defp active_tab(_action), do: :calculator

  def todays_date do
    {year, month, day} = DateTime.now!("Europe/Sarajevo") |> DateTime.to_date() |> Date.to_erl()
    "#{day}.#{month}.#{year}"
  end

  def convert_date(datetime) do
    {year, month, day} = Date.to_erl(datetime)
    "#{day}.#{month}.#{year}"
  end
end
