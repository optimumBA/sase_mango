defmodule SaseMangoWeb.InvestorsListLive.Show do
  use SaseMangoWeb, :live_view

  alias SaseMango.HandleTable
  alias SaseMango.HandleTable.SearchFilter
  alias SaseMango.InvestorsCache
  alias SaseMangoWeb.SecuritiesLive.FilterFormComponent
  alias SaseMangoWeb.SecuritiesLive.TableComponents
  alias SaseMangoWeb.SharedComponents.HeaderComponent

  @impl Phoenix.LiveView
  def mount(%{"slug" => investor_slug} = _params, _session, socket) do
    {:ok,
     socket
     |> assign(:page, 1)
     |> assign(:per_page, 15)
     |> assign(:active_tab, :investors_list)
     |> assign(:sortable, false)
     |> assign(:investor_slug, investor_slug)
     |> assign_table_columns()
     |> assign(:investor, InvestorsCache.get_investor(investor_slug))}
  end

  @impl Phoenix.LiveView
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign_url_options(params)
     |> maybe_filter_table_and_assign()}
  end

  defp assign_url_options(socket, params) do
    sort_by = params["sort_by"] || "price"
    sort_order = HandleTable.set_sort_order(params["sort_order"])
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    filter_options = %SearchFilter{q: params["q"] || nil}

    socket
    |> assign(:filter_options, filter_options)
    |> assign(:sort_options, sort_options)
  end

  defp assign_table_columns(socket) do
    table_columns = [
      %{id: "sort-name", title: "Issuer name", type: :text, name: "name"},
      %{id: "sort-number", title: "Shares number", type: :number, name: "investor_shares_number"},
      %{id: "sort-capital", title: "Total shares value", type: :number, name: "price"}
    ]

    assign(socket, :table_columns, table_columns)
  end

  @impl Phoenix.LiveView
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

  defp filter(list, query) do
    term = String.downcase(query)

    Enum.filter(list, &String.contains?(String.downcase(&1.name), term))
  end

  defp format_path(socket, url_options) do
    query_url_params = HandleTable.merge_url_params(socket, url_options)
    slug_name = socket.assigns.investor_slug
    ~p"/investors/#{slug_name}/?#{query_url_params}"
  end

  defp maybe_filter_table_and_assign(%{assigns: %{filter_options: %{q: query}}} = socket)
       when is_binary(query) do
    list = socket.assigns.investor.issuers_list
    sort_table(socket, filter(list, query))
  end

  defp maybe_filter_table_and_assign(socket) do
    cur_page = socket.assigns.page
    per_page = socket.assigns.per_page
    list = socket.assigns.investor.issuers_list
    sort_table(socket, Enum.slice(list, 0, cur_page * per_page))
  end

  defp sort_table(
         %{assigns: %{sort_options: %{sort_by: field, sort_order: sort_order}, sortable: true}} =
           socket,
         list
       )
       when sort_order in [:asc, :desc] do
    sorted_table_list = HandleTable.sort_table(list, field, sort_order)

    assign(socket, :table_list, sorted_table_list)
  end

  defp sort_table(%{assigns: %{sort_options: _sort_options}} = socket, list) do
    assign(socket, :table_list, list)
  end

  defp sort_table(socket, _list), do: socket
end
