defmodule SaseMangoWeb.SecuritiesLive.Show do
  @moduledoc false

  alias SaseMango.Securities
  alias SaseMango.SecuritiesHelper

  use SaseMangoWeb, :live_view

  @impl Phoenix.LiveView
  def mount(%{"symbol" => symbol} = _params, _session, socket) do
    case Securities.get_company_data(symbol) do
      nil ->
        {:ok, redirect(socket, to: "/")}

      company_data ->
        {:ok,
         socket
         |> assign(:company_data, company_data)
         |> assign(:page_title, "Issuer profile - #{symbol}")}
    end
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
      <section class="w-full min-h-screen bg-gray-50">
        <header class="relative flex items-center justify-between flex-col md:flex-row p-4 md:px-10 border-b shadow-md mb-4">
          <h2 class="text-2xl md:text-3xl xl:text-4xl"> Issuer profile </h2>

          <div class="flex flex-col items-center md:items-end">
            <h5 class="font-light text-xl md:text-2xl"> Company information </h5>

            <a href={"http://www.sase.ba/v1/Tržište/Emitenti/Profil-emitenta/symbol/#{@company_data.symbol}"} target="_blank"
              class="text-gray-800 hover:text-blue-dark-500"
            >
              <p class="font-semibold text-lg md:text-xl uppercase mx-auto"> <%= @company_data.name %> </p>
            </a>
          </div>
        </header>

        <div class="md:w-5/6 xl:w-3/4 p-4 mx-auto grid grid-cols-1 lg:grid-cols-2 gap-8">

            <table id="table-general-info" class="table-auto mx-auto w-full h-max row-span-3">
              <thead class="p-2 bg-blue-dark-200">
                <tr>
                  <th colspan="2" class="px-6 py-3 rounded-lg text-white uppercase text-sm">Symbol data</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-xs md:text-sm">
                <tr>
                  <td class="px-2 py-3 text-left"><b>ISIN</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.isin %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Short name</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.short_name %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Company</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.company %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Address</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.address %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Contact</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.contact %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Email</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.email %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Web page</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.web_page %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Activity</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.activity %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>External auditor</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.external_auditor %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Audit Committee</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.audit_committee %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Number Of Employees</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.number_of_employees %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>NumberOfBussinesUnits</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.symbol_data.number_of_bussines_units %></td>
                </tr>
              </tbody>
            </table>

            <table id="table-management-board" class="table-auto xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2 bg-blue-dark-200">
                <tr>
                  <th colspan="2" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Management Board</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-xs md:text-sm">

                <%= for {person_name, position} <- @company_data.management_board do %>
                  <tr>
                    <td class="px-2 py-3 text-left"><b><%= person_name %></b></td>
                    <td class="px-2 py-3 text-left"><%= position %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <table id="table-supervisory-board" class="table-auto xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2 bg-blue-dark-200">
                <tr >
                  <th colspan="2" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Supervisory Board</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-xs md:text-sm">

                <%= for {person_name, position} <- @company_data.supervisory_board do %>
                  <tr>
                    <td class="px-2 py-3 text-left"><b><%= person_name %></b></td>
                    <td class="px-2 py-3 text-left"><%= position %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <%= unless is_nil(@company_data.management_shares) do %>
              <table id="table-management-shared" class="table-auto xl:place-self-start w-full h-max row-span-1">
                <thead class="p-2 bg-blue-dark-200">
                  <tr>
                    <th colspan="2" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Management Shares</th>
                  </tr>
                </thead>
                <tbody class="bg-gray-100 text-xs md:text-sm">
                    <tr>
                      <td class="px-2 py-3 text-left"><%= @company_data.management_shares %></td>
                    </tr>
                </tbody>
              </table>
            <% end %>

            <table id="table-shareholders-data" class="table-auto xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2 bg-blue-dark-200">
                <tr>
                  <th colspan="2" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Securities and Shareholders Data</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-xs md:text-sm">
                <tr>
                  <td class="px-2 py-3 text-left"><b>Total Number Of Shareholders</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.securities_and_shareholders_data.total_number_of_shareholders %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Number Of Shares Nominal Price</b></td>
                  <td class="px-2 py-3 text-left flex">
                  <a href={@company_data.securities_and_shareholders_data.sase_url} target="_blank"
                    class="pr-2 text-blue-300"
                  >
                    <%= @company_data.symbol %>
                  </a>
                  <span><%= @company_data.securities_and_shareholders_data.number_of_shares_nominal_price %></span>
                  </td>
                </tr>
              </tbody>
            </table>

            <%= unless Enum.empty?(@company_data.top_10_owners) do %>
              <table id="table-top-10-owners" class="table-auto xl:justify-self-start w-full h-max row-span-3">
                <thead class="p-2 bg-blue-dark-200">
                  <tr>
                    <th colspan="3" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Top 10 Owners</th>
                  </tr>
                </thead>
                <tbody class="bg-gray-100 text-xs md:text-sm">
                  <tr>
                    <td class="px-2 py-3 text-left"><b>Name</b></td>
                    <td class="px-2 py-3 text-left"><b>Percent</b></td>
                    <td class="px-2 py-3 text-left"><b>Date</b></td>
                  </tr>
                  <%= for owner <- @company_data.top_10_owners do %>
                    <tr>
                      <td class="px-2 py-3 text-left"><%= owner["naziv"] %></td>
                      <td class="px-2 py-3 text-left"><%= owner["procenti"] %>%</td>
                      <td class="px-2 py-3 text-left"><%= SecuritiesHelper.format_date(owner["datum"]) %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            <% end %>
        </div>
      </section>
    """
  end
end
