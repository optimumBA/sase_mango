defmodule SaseMangoWeb.SecuritiesLive.Show do
  @moduledoc false

  use SaseMangoWeb, :live_view

  alias SaseMango.HandleTable
  alias SaseMango.Securities
  alias SaseMango.SecuritiesHelper
  alias SaseMangoWeb.SecuritiesLive.TableComponents
  alias SaseMangoWeb.SharedComponents.TableIconsComponent

  @impl Phoenix.LiveView
  def mount(%{"symbol" => symbol} = _params, _session, socket) do
    case Securities.get_company_data(symbol) do
      nil ->
        {:ok, redirect(socket, to: "/")}

      company_data ->
        {:ok,
         socket
         |> assign(:symbol, symbol)
         |> assign(:company_data, company_data)
         |> assign_symbol_data_fields(company_data)
         |> assign_top_10_owners(company_data)
         |> assign_top_10_owners_table_columns()
         |> assign(:sortable, false)
         |> assign(:page_title, "Issuer profile - #{symbol}")}
    end
  end

  @impl Phoenix.LiveView
  def handle_params(params,_url, socket) do
    {:noreply,
    socket
    |> assign_url_options(params)
    |> sort_top_owners()}
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

    {:noreply,
     socket
     |> assign(:sortable, true)
     |> push_patch(to: ~p"/issuer/#{socket.assigns.symbol}?#{sort_options}", replace: true)}
  end

  defp assign_url_options(socket, params) do
    sort_by = params["sort_by"] || "percentage_shares"
    sort_order = HandleTable.set_sort_order(params["sort_order"])
    sort_options = %{sort_by: sort_by, sort_order: sort_order}

    assign(socket, :sort_options, sort_options)
  end


  defp assign_symbol_data_fields(socket, %{symbol_data: symbol_data} = _company_data) do
    data_rows = [
      %{title: "ISIN", value: symbol_data.isin},
      %{title: "Short name", value: symbol_data.short_name},
      %{title: "Company", value: symbol_data.company},
      %{title: "Address", value: symbol_data.address},
      %{title: "Contact", value: symbol_data.contact},
      %{title: "Email", value: symbol_data.email},
      %{title: "Web page", value: symbol_data.web_page},
      %{title: "Activity", value: symbol_data.activity},
      %{title: "External auditor", value: symbol_data.external_auditor},
      %{title: "Audit Committee", value: symbol_data.audit_committee},
      %{title: "Number Of Employees", value: symbol_data.number_of_employees},
      %{title: "Number Of Bussines Units", value: symbol_data.number_of_bussines_units}
    ]

    assign(socket, :symbol_data_rows, data_rows)
  end

  defp assign_top_10_owners(socket, %{top_10_owners: top_10_owners} = _company_data) do
    top_10_owners =
      Enum.reduce(top_10_owners, [], fn owner, owners_list ->
        owner_data =
          Map.merge(owner, %{
            "name_slug" => HandleTable.create_slug(owner["naziv"])
          })

        [owner_data | owners_list]
      end)
      |> Enum.sort_by(&Map.fetch(&1, "procenti"), :desc)


    assign(socket, :top_10_owners, top_10_owners)
  end

  defp assign_top_10_owners_table_columns(socket) do
    table_columns = [
      %{id: "sort-percentage", title: "Percent", type: :number, name: "percentage_shares"}
    ]

    assign(socket, :top_10_owners_columns, table_columns)
  end

  defp sort_top_owners(%{assigns: %{sort_options: %{sort_order: sort_order}, sortable: true, top_10_owners: list}} =
   socket)
    when sort_order in [:asc, :desc]
   do
    if sort_order == :desc do
      assign(socket, :top_10_owners, Enum.sort_by(list, &Map.fetch(&1, "procenti"), :desc))
    else
      assign(socket, :top_10_owners,Enum.sort_by(list, &Map.fetch(&1, "procenti")))
    end
  end

  defp sort_top_owners(%{assigns: %{sort_options: _sort_options}, top_10_owners: list} = socket) do

    assign(socket, :top_10_owners, list)
  end

  defp sort_top_owners(socket), do: socket

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
    <section class="w-full min-h-screen">
      <header class="py-4 px-4 md:px-0 border-b shadow-md mb-4">
        <div class="w-full md:w-11/12 xl:w-3/4 mx-auto px-2 md:px-0 py-2 mt-10">
          <div class="relative ml-6 md:ml-0">
            <TableIconsComponent.issuer_link
              company_symbol={@company_data.symbol}
              company_name={@company_data.name}
            />
            <.link navigate={~p"/"} class="absolute top-1/2 left-0 -translate-x-8 -translate-y-1/2">
              <TableIconsComponent.icon_back />
            </.link>
          </div>
          <p class="font-light text-gray-450 text-sm ml-6 mt-2 md:ml-0">Company information</p>
        </div>
      </header>

      <div class="md:w-11/12 xl:w-3/4 py-4 mx-auto px-2 mt-8 md:px-0 grid grid-cols-1 lg:grid-cols-2 gap-8">
        <table
          id="table-general-info"
          class="table-auto border-separate mx-auto w-full h-max row-span-3"
        >
          <thead class="p-2">
            <tr>
              <th
                colspan="2"
                class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm"
              >
                Symbol data
              </th>
            </tr>
          </thead>
          <tbody class="text-xs md:text-sm border border-t-0">
            <tr :for={symbol_data <- @symbol_data_rows}>
              <%= if symbol_data.title == "Web page" do %>
                <td class="py-3 text-left border-l bg-slate-50"><b>Web page</b></td>
                <td class="px-2 py-3 text-left border-r bg-slate-50">
                  <a
                    href={"https://#{symbol_data.value}"}
                    target="_blank"
                    class="pr-2 text-blue-dark-500 hover:underline font-light"
                  >
                    <%= symbol_data.value %>
                  </a>
                </td>
              <% else %>
                <td class="py-3 text-left border-l bg-slate-50"><b><%= symbol_data.title %></b></td>
                <td class="px-2 py-3 text-left border-r bg-slate-50"><%= symbol_data.value %></td>
              <% end %>
            </tr>
          </tbody>
        </table>

        <table
          id="table-top-10-owners"
          class="table-auto border-separate xl:justify-self-start w-full h-max row-span-3"
        >
          <thead class="p-2">
            <tr>
              <th
                colspan="3"
                class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm"
              >
                Top 10 Owners
              </th>
            </tr>
          </thead>
          <tbody class="text-xs md:text-sm border border-t-0">
            <tr class="text-gray-400 bg-slate-50">
            <td class="py-3 text-left border-l"><b>Name</b></td>
              <td :for={table_column <- @top_10_owners_columns} class="pl-0 py-3 text-left">
                <div>
                <TableComponents.sort_link column={table_column} sort_options={@sort_options} class="font-bold"/>
                </div>
              </td>
              <td class="pl-0 py-3 text-left border-r"><b>Date</b></td>
            </tr>
            <tr :for={owner <- @top_10_owners}>
              <td class="py-3 text-left font-semibold border-l bg-slate-50">
                <.link navigate={~p"/investors/#{owner["name_slug"]}"} class="text-blue-dark-500">
                  <span><%= owner["naziv"] %></span>
                </.link>
              </td>
              <td class="pl-0 py-3 text-left bg-slate-50"><%= owner["procenti"] %>%</td>
              <td class="pl-0 py-3 text-left border-r bg-slate-50">
                <%= SecuritiesHelper.format_date(owner["datum"]) %>
              </td>
            </tr>
          </tbody>
        </table>

        <table
          id="table-management-board"
          class="table-auto border-separate xl:place-self-start w-full h-max row-span-1"
        >
          <thead class="p-2">
            <tr>
              <th
                colspan="2"
                class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm"
              >
                Management Board
              </th>
            </tr>
          </thead>
          <tbody class="text-xs md:text-sm">
            <tr :for={{position, person_name} <- @company_data.management_board}>
              <td class="py-3 text-left font-semibold border-l bg-slate-50 first-letter:uppercase">
                <b><%= position %></b>
              </td>
              <td class="pl-0 py-3 text-left border-r bg-slate-50"><%= person_name %></td>
            </tr>
          </tbody>
        </table>

        <table
          id="table-supervisory-board"
          class="table-auto border-separate xl:place-self-start w-full h-max row-span-1"
        >
          <thead class="p-2">
            <tr>
              <th
                colspan="2"
                class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm"
              >
                Supervisory Board
              </th>
            </tr>
          </thead>
          <tbody class="text-xs md:text-sm">
            <tr :for={{position, person_name} <- @company_data.supervisory_board}>
              <td class="py-3 text-left font-semibold border-l bg-slate-50 first-letter:uppercase">
                <b><%= position %></b>
              </td>
              <td class="pl-0 py-3 text-left border-r bg-slate-50"><%= person_name %></td>
            </tr>
          </tbody>
        </table>

        <table
          id="table-shareholders-data"
          class="table-auto border-separate xl:place-self-start w-full h-max row-span-1"
        >
          <thead class="p-2">
            <tr>
              <th
                colspan="2"
                class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm"
              >
                Securities and Shareholders Data
              </th>
            </tr>
          </thead>
          <tbody class="text-xs md:text-sm">
            <tr>
              <td class="py-3 text-left font-semibold border-l bg-slate-50">
                <b>Total Number Of Shareholders</b>
              </td>
              <td class="pl-0 py-3 text-left border-r bg-slate-50">
                <%= @company_data.securities_and_shareholders_data.total_number_of_shareholders %>
              </td>
            </tr>
            <tr>
              <td class="py-3 text-left font-semibold border-l bg-slate-50">
                <b>Number Of Shares Nominal Price</b>
              </td>
              <td class="pl-0 py-3 flex flex-col text-left border-r bg-slate-50 flex">
                <div
                  :for={
                    {symbol, shares, nominal_price} <-
                      @company_data.securities_and_shareholders_data.shares_nominal_price
                  }
                  class="py-1"
                >
                  <a
                    href={"http://www.sase.ba/v1/Tržište/Emitenti/Profil-emitenta/symbol/#{symbol}"}
                    target="_blank"
                    class="pr-2 text-blue-dark-500 hover:underline"
                  >
                    <%= symbol %>
                  </a>
                  <span>- <%= shares %> - <%= nominal_price %></span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>

        <%= unless is_nil(@company_data.management_shares) do %>
          <table
            id="table-management-shared"
            class="table-auto border-separate xl:place-self-start w-full h-max row-span-1 lg:col-span-2"
          >
            <thead class="p-2">
              <tr>
                <th
                  colspan="2"
                  class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 text-white text-left uppercase text-xs md:text-sm"
                >
                  Management Shares
                </th>
              </tr>
            </thead>
            <tbody class="text-xs md:text-sm">
              <tr>
                <td class="py-3 text-left bg-slate-50"><%= @company_data.management_shares %></td>
              </tr>
            </tbody>
          </table>
        <% end %>

        <%= unless is_nil(@company_data.legal_entities) do %>
          <table
            id="table-legal-entities"
            class="table-auto border-separate xl:place-self-start w-full h-max row-span-1 lg:col-span-2"
          >
            <thead class="p-2">
              <tr>
                <th
                  colspan="2"
                  class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 text-white text-left uppercase text-xs md:text-sm"
                >
                  Legal Entities Owned By Issuer
                </th>
              </tr>
            </thead>
            <tbody class="text-xs md:text-sm">
              <tr>
                <td class="py-3 text-lef bg-slate-50"><%= @company_data.legal_entities %></td>
              </tr>
            </tbody>
          </table>
        <% end %>
      </div>
    </section>
    """
  end
end
# <td class="py-3 text-left border-l"><b>Name</b></td>
#               <td class="pl-0 py-3 text-left"><b>Percent</b></td>
#
