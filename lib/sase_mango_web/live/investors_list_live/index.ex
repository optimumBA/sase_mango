defmodule SaseMangoWeb.InvestorsListLive.Index do
  use SaseMangoWeb, :live_view

  alias Phoenix.Socket.Broadcast
  alias SaseMango.HandleTable
  alias SaseMango.HandleTable.SearchFilter
  alias SaseMango.InvestorsCache
  alias SaseMangoWeb.Endpoint
  alias SaseMangoWeb.SecuritiesLive.FilterFormComponent
  alias SaseMangoWeb.SecuritiesLive.TableComponents
  alias SaseMangoWeb.SharedComponents.HeaderComponent

  @impl Phoenix.LiveView
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Endpoint.subscribe("investors")
    end

    {:ok,
     socket
     |> assign(:page, 1)
     |> assign(:per_page, 15)
     |> assign(:page_title, "List of investors")
     |> assign(:active_tab, :investors_list)
     |> assign(:sortable, false)
     |> assign_table_columns(:investors_list)}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_url_options(params)
     |> maybe_filter_table_and_assign()}
  end

  defp assign_url_options(socket, params) do
    sort_by = params["sort_by"] || "total_capital"
    sort_order = HandleTable.set_sort_order(params["sort_order"])
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    filter_options = %SearchFilter{q: params["q"] || nil}

    socket
    |> assign(:filter_options, filter_options)
    |> assign(:sort_options, sort_options)
  end

  defp assign_table_columns(socket, :investors_list) do
    table_columns = [
      %{id: "sort-name", title: "Investors", type: :text, name: "name"},
      %{id: "sort-number", title: "Companies number", type: :number, name: "company_number"},
      %{id: "sort-capital", title: "Total capital", type: :number, name: "total_capital"}
    ]

    assign(socket, :table_columns, table_columns)
  end

  @impl Phoenix.LiveView
  def handle_info(%Broadcast{event: "investors_update"}, socket) do
    {:noreply, maybe_filter_table_and_assign(socket)}
  end

  def handle_info({:url_update, options}, socket) do
    path = format_path(socket, options)
    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  @impl Phoenix.LiveView
  def handle_event("sort_column", %{"col_name" => name} = _params, socket) do
    %{sort_options: %{sort_by: col_name, sort_order: sort_order}} = socket.assigns

    maybe_update_sort_order =
      if col_name != name do
        :asc
      else
        HandleTable.revert_sort_order(sort_order)
      end

    sort_options = %{sort_by: name, sort_order: maybe_update_sort_order}
    path = format_path(socket, sort_options)

    {:noreply,
     socket
     |> assign(:sortable, true)
     |> push_patch(to: path, replace: true)}
  end

  def handle_event("load_more", _params, socket) do
    current_page = socket.assigns.page

    {:noreply,
     socket
     |> assign(:page, current_page + 1)
     |> assign(:sortable, false)
     |> maybe_filter_table_and_assign()}
  end

  def handle_event("clear_form", _params, socket) do
    path = format_path(socket, %{q: nil})
    {:noreply, push_patch(socket, to: path, replace: true)}
  end

  defp format_path(socket, url_options) do
    query_url_params = HandleTable.merge_url_params(socket, url_options)

    ~p"/investors?#{query_url_params}"
  end

  defp maybe_filter_table_and_assign(%{assigns: %{filter_options: %{q: query}}} = socket)
       when is_binary(query) do
    sort_table(socket, InvestorsCache.filter_investor_list(query))
  end

  defp maybe_filter_table_and_assign(socket) do
    cur_page = socket.assigns.page
    per_page = socket.assigns.per_page

    investors_list = InvestorsCache.get(cur_page * per_page)

    sort_table(socket, investors_list)
  end

  defp sort_table(
         %{assigns: %{sort_options: %{sort_by: field, sort_order: sort_order}, sortable: true}} =
           socket,
         list
       )
       when sort_order in [:asc, :desc] do
    sorted_table_list = HandleTable.sort_table(list, field, sort_order)

    assign(socket, :investors_list, sorted_table_list)
  end

  defp sort_table(%{assigns: %{sort_options: _sort_options}} = socket, list) do
    assign(socket, :investors_list, list)
  end

  defp sort_table(socket, _list), do: socket

  defp investor_list_with_index(investors_list) do
    Enum.with_index(investors_list,
      fn investor, index -> {index + 1, investor} end)
  end
end
