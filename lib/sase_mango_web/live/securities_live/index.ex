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

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_filter_options(params)
     |> assign_sort_options(params)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :securities, _params) do
    socket
    |> assign(:page_title, "List of securities")
    |> assign(:active_tab, :securities)
    |> assign_list_of_securities()
    |> maybe_filter_securities(:securities)
  end

  defp apply_action(socket, :bargains, _params) do
    socket
    |> assign(:page_title, "Bargain securities")
    |> assign(:active_tab, :bargains)
    |> assign_list_of_bargains()
    |> maybe_filter_securities(:bargains)
  end

  defp assign_list_of_securities(socket),
    do: assign(socket, :securities, SecuritiesCache.get_securities())

  defp assign_list_of_bargains(socket),
    do: assign(socket, :securities, BargainsCache.get_bargains())

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
    |> assign_list_of_securities()
    |> maybe_filter_securities(:securities)
  end

  defp update_securities(socket, :bargains) do
    socket
    |> assign_list_of_bargains()
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

  defp maybe_filter_securities(
         %{assigns: %{filter_options: %{q: search_value}}} = socket,
         action_type
       )
       when is_binary(search_value) do
    search_value = String.downcase(search_value)

    filtered_securities_list =
      case action_type do
        :securities ->
          filter(SecuritiesCache.get_securities(), search_value)

        :bargains ->
          filter(SecuritiesCache.get_securities(), search_value)
      end

    sort_securities(socket, filtered_securities_list)
  end

  defp maybe_filter_securities(socket, _action),
    do: sort_securities(socket, socket.assigns.securities)

  defp filter(list, search_value) do
    Enum.filter(
      list,
      &(String.starts_with?(String.downcase(&1.symbol), search_value) ||
          String.starts_with?(String.downcase(&1.name), search_value))
    )
  end

  defp sort_securities(
         %{assigns: %{sort_options: %{sort_by: field, sort_order: sort_order}}} = socket,
         list
       )
       when sort_order in [:asc, :desc] do
    assign(socket, :securities, HandleTable.sort_table(list, field, sort_order))
  end

  defp sort_securities(socket, _list), do: socket

  defp set_sort_order("asc"), do: :asc
  defp set_sort_order("desc"), do: :desc
  defp set_sort_order(_value), do: :desc
end
