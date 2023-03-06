defmodule SaseMangoWeb.SecuritiesLive.Show do
  @moduledoc false

  use SaseMangoWeb, :live_view

  alias SaseMango.Securities
  alias SaseMango.SecuritiesHelper
  alias SaseMangoWeb.SharedComponents.TableIconsComponent

  @impl Phoenix.LiveView
  def mount(%{"symbol" => symbol} = _params, _session, socket) do
    case Securities.get_company_data(symbol) do
      nil ->
        {:ok, redirect(socket, to: "/")}

      company_data ->
        {:ok,
         socket
         |> assign(:company_data, company_data)
         |> assign_symbol_data_fields(company_data)
         |> assign(:page_title, "Issuer profile - #{symbol}")}
    end
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

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
      <section class="w-full min-h-screen">
        <header class="p-4 border-b shadow-md mb-4">
          <div class="w-full md:w-11/12 xl:w-3/4 mx-auto px-2 md:px-0 py-2 mt-8">
            <div class="relative ml-6 md:ml-0">
              <h2 class="text-blue-dark-200 text-lg font-semibold md:text-2xl mb-2 tracking-wide">
                <%= @company_data.name %>
              </h2>
              <%= live_redirect to: Routes.securities_index_path(@socket, :securities), class: "absolute top-1/2 left-0 -translate-x-8 -translate-y-1/2" do %>
                <TableIconsComponent.icon_back />
              <% end %>
            </div>
            <p class="font-light text-gray-450 text-sm ml-6 md:ml-0">Company information</p>
          </div>
        </header>

        <div class="md:w-11/12 xl:w-3/4 py-4 mx-auto px-2 mt-8 md:px-0 grid grid-cols-1 lg:grid-cols-2 gap-8">
            <table id="table-general-info" class="table-auto border-separate mx-auto w-full h-max row-span-3">
              <thead class="p-2">
                <tr>
                  <th colspan="2" class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm">
                    Symbol data
                  </th>
                </tr>
              </thead>
              <tbody class="text-xs md:text-sm border border-t-0">
                <%= for symbol_data <- @symbol_data_rows do %>
                  <%= if symbol_data.title == "Web page" do %>
                    <tr>
                      <td class="py-3 text-left border-l bg-slate-50"><b>Web page</b></td>
                      <td class="px-2 py-3 text-left border-r bg-slate-50">
                        <a href={"https://#{symbol_data.value}"} target="_blank"
                          class="pr-2 text-blue-dark-500 hover:underline font-light"
                        >
                          <%= symbol_data.value %>
                        </a>
                      </td>
                    </tr>
                    <% else %>
                    <tr>
                      <td class="py-3 text-left border-l bg-slate-50"><b><%= symbol_data.title %></b></td>
                      <td class="px-2 py-3 text-left border-r bg-slate-50"><%= symbol_data.value %></td>
                    </tr>
                  <% end %>
                <% end %>
              </tbody>
            </table>

            <table id="table-top-10-owners" class="table-auto border-separate xl:justify-self-start w-full h-max row-span-3">
              <thead class="p-2">
                <tr>
                  <th colspan="3" class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm">
                    Top 10 Owners
                  </th>
                </tr>
              </thead>
              <tbody class="text-xs md:text-sm border border-t-0">
                <tr class="text-gray-400 bg-slate-50">
                  <td class="py-3 text-left border-l"><b>Name</b></td>
                  <td class="pl-0 py-3 text-left"><b>Percent</b></td>
                  <td class="pl-0 py-3 text-left border-r"><b>Date</b></td>
                </tr>
                <%= for owner <- @company_data.top_10_owners do %>
                  <tr>
                    <td class="py-3 text-left font-semibold border-l bg-slate-50"><%= owner["naziv"] %></td>
                    <td class="pl-0 py-3 text-left bg-slate-50"><%= owner["procenti"] %>%</td>
                    <td class="pl-0 py-3 text-left border-r bg-slate-50"><%= SecuritiesHelper.format_date(owner["datum"]) %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <table id="table-management-board" class="table-auto border-separate xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2">
                <tr>
                  <th colspan="2" class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm">Management Board</th>
                </tr>
              </thead>
              <tbody class="text-xs md:text-sm">
                <%= for {position, person_name} <- @company_data.management_board do %>
                  <tr>
                    <td class="py-3 text-left font-semibold border-l bg-slate-50 first-letter:uppercase"><b><%= position %></b></td>
                    <td class="pl-0 py-3 text-left border-r bg-slate-50"><%= person_name %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <table id="table-supervisory-board" class="table-auto border-separate xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2">
                <tr >
                  <th colspan="2" class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm">Supervisory Board</th>
                </tr>
              </thead>
              <tbody class="text-xs md:text-sm">
                <%= for {position, person_name} <- @company_data.supervisory_board do %>
                  <tr>
                    <td class="py-3 text-left font-semibold border-l bg-slate-50 first-letter:uppercase"><b><%= position %></b></td>
                    <td class="pl-0 py-3 text-left border-r bg-slate-50"><%= person_name %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <table id="table-shareholders-data" class="table-auto border-separate xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2">
                <tr>
                  <th colspan="2" class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 rounded-tl-xl rounded-tr-xl border border-blue-dark-200 text-white text-left uppercase text-xs md:text-sm">
                    Securities and Shareholders Data
                  </th>
                </tr>
              </thead>
              <tbody class="text-xs md:text-sm">
                <tr>
                  <td class="py-3 text-left font-semibold border-l bg-slate-50"><b>Total Number Of Shareholders</b></td>
                  <td class="pl-0 py-3 text-left border-r bg-slate-50"><%= @company_data.securities_and_shareholders_data.total_number_of_shareholders %></td>
                </tr>
                <tr>
                  <td class="py-3 text-left font-semibold border-l bg-slate-50"><b>Number Of Shares Nominal Price</b></td>
                  <td class="pl-0 py-3 flex flex-col text-left border-r bg-slate-50 flex">
                    <%= for {symbol, shares, nominal_price} <- @company_data.securities_and_shareholders_data.shares_nominal_price do %>
                      <div class="py-1">
                        <a href={"http://www.sase.ba/v1/Tržište/Emitenti/Profil-emitenta/symbol/#{symbol}"} target="_blank" class="pr-2 text-blue-dark-500 hover:underline">
                          <%= symbol %>
                        </a>
                        <span> - <%= shares %> - <%= nominal_price %></span>
                      </div>
                    <% end %>
                  </td>
                </tr>
              </tbody>
            </table>

            <%= unless is_nil(@company_data.management_shares) do %>
              <table id="table-management-shared" class="table-auto border-separate xl:place-self-start w-full h-max row-span-1 lg:col-span-2">
                <thead class="p-2">
                  <tr>
                    <th colspan="2" class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 text-white text-left uppercase text-xs md:text-sm">Management Shares</th>
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
              <table id="table-legal-entities" class="table-auto border-separate xl:place-self-start w-full h-max row-span-1 lg:col-span-2">
                <thead class="p-2">
                  <tr>
                    <th colspan="2" class="px-4 py-2 md:px-6 md:py-3 bg-blue-dark-200 text-white text-left uppercase text-xs md:text-sm">
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
