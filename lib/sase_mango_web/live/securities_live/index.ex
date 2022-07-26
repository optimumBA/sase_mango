defmodule SaseMangoWeb.SecuritiesLive.Index do
  use SaseMangoWeb, :live_view

  alias SaseMango.HandleTable
  alias SaseMango.Securities
  alias SaseMangoWeb.Components.SortingComponent
  alias SaseMangoWeb.Endpoint
  alias Phoenix.Socket.Broadcast

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("securities")
    end

    {:ok, socket}
  end

  def handle_params(%{"sort_by" => sort_by, "sort_order" => sort_order} = params, _url, socket) do
    new_sort_by = sort_by || "symbol"
    new_sort_order = set_sort_order(sort_order)

    sort_options = %{sort_by: new_sort_by, sort_order: new_sort_order}

    socket =
      socket
      |> apply_action(socket.assigns.live_action, params)
      |> assign(:sort_options, sort_options)
      |> sort_securities(sort_options)

    {:noreply, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:sort_options, %{sort_by: nil, sort_order: nil})
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_info(%Broadcast{event: "securities_update"}, socket) do
    {:noreply, assign(socket, :securities, list_securities())}
  end

  @impl true
  def handle_event("sort_column", %{"key" => key} = _params, socket) do
    %{sort_options: %{sort_order: sort_order}} = socket.assigns

    sort_order = if sort_order == :asc, do: :desc, else: :asc
    sort_options = %{sort_by: key, sort_order: sort_order}

    url_params = merge_url_params(socket, sort_options)
    path = Routes.securities_index_path(socket, socket.assigns.live_action, url_params)

    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp apply_action(socket, :securities, _params) do
    socket
    |> assign(:page_title, "List of securities")
    |> assign(:active_tab, :securities)
    |> assign(:securities, [])
  end

  defp apply_action(socket, :bargains, _params) do
    socket
    |> assign(:page_title, "Bargain securities")
    |> assign(:active_tab, :bargains)
    |> assign(:securities, list_securities())
  end

  defp merge_url_params(socket, options) do
    %{sort_options: sort_options} = socket.assigns

    url_params =
      %{}
      |> Map.merge(sort_options)
      |> Map.merge(options)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    url_params
  end

  defp list_securities(), do: Securities.list_securities()

  defp set_sort_order("asc"), do: :asc
  defp set_sort_order("desc"), do: :desc
  defp set_sort_order(_value), do: :asc

  defp sort_securities(socket, %{sort_by: field, sort_order: sort_order})
       when sort_order in [:asc, :desc] do
    securities = socket.assigns.securities

    assign(socket, :securities, HandleTable.sort_table(securities, field, sort_order))
  end

  defp sort_securities(socket, _sort_options), do: socket

  def todays_date do
    {year, month, day} = DateTime.now!("Europe/Sarajevo") |> DateTime.to_date() |> Date.to_erl()
    "#{day}.#{month}.#{year}"
  end
end
