defmodule SaseMangoWeb.SecuritiesLive.Index do
  use SaseMangoWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias SaseMango.BargainsCache
  alias SaseMango.HandleTable
  alias SaseMango.HandleTable.SearchFilter
  alias SaseMango.Securities
  alias SaseMango.SecuritiesCache
  alias SaseMangoWeb.Endpoint
  alias SaseMangoWeb.SecuritiesLive.FilterFormComponent
  alias SaseMangoWeb.SecuritiesLive.SortingComponent
  alias SaseMangoWeb.SecuritiesLive.TableRowComponent
  alias SaseMangoWeb.SharedComponents.HeaderComponent

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("securities")
    end

    {:ok,
     socket
     |> assign(:active_tab, socket.assigns.live_action)
     |> assign_list_securities(socket.assigns.live_action)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket =
      if socket.assigns.live_action != socket.assigns.active_tab do
        assign_list_securities(socket, socket.assigns.live_action)
      else
        socket
      end

    {:noreply,
     socket
     |> assign_filter_options(params)
     |> assign_sort_options(params)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp assign_sort_options(socket, params) do
    new_sort_by = params["sort_by"] || "eps_roi"
    new_sort_order = set_sort_order(params["sort_order"])
    sort_options = %{sort_by: new_sort_by, sort_order: new_sort_order}

    assign(socket, :sort_options, sort_options)
  end

  defp assign_filter_options(socket, params) do
    assign(socket, :filter_options, %SearchFilter{q: params["q"] || nil})
  end

  @impl true
  def handle_info(%Broadcast{event: "securities_update"}, socket) do
    {:noreply, update_securities(socket, socket.assigns.live_action)}
  end

  def handle_info({:url_update, options}, socket) do
    url_params = merge_url_params(socket, options)
    path = Routes.securities_index_path(socket, socket.assigns.live_action, url_params)

    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp update_securities(socket, :securities) do
    socket
    |> assign_list_securities(:securities)
    |> maybe_filter_securities(:securities)
  end

  defp update_securities(socket, :bargains) do
    socket
    |> assign_list_securities(:bargains)
    |> maybe_filter_securities(:bargains)
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

  def handle_event("clear_form", _params, socket) do
    url_params = merge_url_params(socket, %{q: nil})
    path = Routes.securities_index_path(socket, socket.assigns.live_action, url_params)

    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp apply_action(socket, :securities, _params) do
    socket
    |> assign(:page_title, "List of securities")
    |> assign(:active_tab, :securities)
    |> maybe_filter_securities(:securities)
  end

  defp apply_action(socket, :bargains, _params) do
    socket
    |> assign(:page_title, "Bargain securities")
    |> assign(:active_tab, :bargains)
    |> maybe_filter_securities(:bargains)
  end

  defp merge_url_params(socket, options) do
    %{sort_options: sort_options, filter_options: filter_options} = socket.assigns

    url_params =
      %{}
      |> Map.merge(sort_options)
      |> Map.merge(Map.from_struct(filter_options))
      |> Map.merge(options)
      |> Enum.reject(fn {_key, value} -> is_nil(value) end)
      |> Map.new()

    url_params
  end

  defp assign_list_securities(socket, :securities) do
    securities = SecuritiesCache.get_securities()

    socket
    |> assign(:securities, securities)
    |> assign(:reserve_list, securities)
  end

  defp assign_list_securities(socket, :bargains) do
    securities = BargainsCache.get_bargains()

    socket
    |> assign(:securities, securities)
    |> assign(:reserve_list, securities)
  end

  defp maybe_filter_securities(%{assigns: %{filter_options: %{q: search_value}}} = socket, action)
       when is_binary(search_value) do
    filtered_securities_list =
      case action do
        :securities ->
          SecuritiesCache.filter_securities(%{q: search_value})

        :bargains ->
          BargainsCache.filter_bargains(%{q: search_value})
      end

    sort_securities(socket, filtered_securities_list)
  end

  defp maybe_filter_securities(socket, _action),
    do: sort_securities(socket, socket.assigns.reserve_list)

  defp sort_securities(
         %{assigns: %{sort_options: %{sort_by: field, sort_order: sort_order}}} = socket,
         list
       )
       when sort_order in [:asc, :desc] do
    assign(socket, :securities, HandleTable.sort_table(list, field, sort_order))
  end

  defp sort_securities(socket, list), do: assign(socket, :securities, list)

  defp set_sort_order("asc"), do: :asc
  defp set_sort_order("desc"), do: :desc
  defp set_sort_order(_value), do: :desc
end
