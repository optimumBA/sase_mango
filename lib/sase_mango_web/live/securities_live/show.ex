defmodule SaseMangoWeb.SecuritiesLive.Show do
  @moduledoc false
  alias SaseMango.Securities

  use SaseMangoWeb, :live_view

  @impl Phoenix.LiveView
  def mount(%{"symbol" => symbol} = _params, _session, socket) do
    company_data = Securities.get_company_data(symbol)

    {:ok,
     socket
     |> assign(:company_data, company_data)
     |> assign(:page_title, "Issuer profile - #{symbol}")}
  end

  def format_date(date) do
    {:ok, date_format} = NaiveDateTime.from_iso8601(date)
    {year, month, day} = date_format |> NaiveDateTime.to_date() |> Date.to_erl()
    "#{day}.#{month}.#{year}"
  end

  @impl Phoenix.LiveView
  def render(assigns) do
    ~H"""
      <section class="w-full min-h-screen bg-gray-50">
        <header class="relative flex flex-col p-4 md:px-10 bg-indigo-500 text-white">
          <h2 class="mx-auto"> Issuer profile </h2>
          <h5 class="font-light mx-auto"> Company information </h5>
          <p class="font-semibold text-xl uppercase mx-auto"> <%= @company_data.name %> </p>

          <a href={"http://www.sase.ba/v1/Tržište/Emitenti/Profil-emitenta/symbol/#{@company_data.symbol}"} target="_blank"
            class="absolute bottom-2 right-2 m-2 text-lg text-blue-100"
          >
            <%= @company_data.symbol %>
          </a>
        </header>

        <div class="md:w-5/6 xl:w-3/4 p-4 mx-auto grid grid-cols-1 lg:grid-cols-2 gap-8">

            <table id="table-general-info" class="table-auto mx-auto w-full h-max row-span-3">
              <thead class="p-2 bg-blue-dark-200">
                <tr>
                  <th colspan="2" class="px-6 py-3 rounded-lg text-white uppercase text-sm">Symbol data</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-sm">
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
              <tbody class="bg-gray-100 text-sm">

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
              <tbody class="bg-gray-100 text-sm">

                <%= for {person_name, position} <- @company_data.supervisory_board do %>
                  <tr>
                    <td class="px-2 py-3 text-left"><b><%= person_name %></b></td>
                    <td class="px-2 py-3 text-left"><%= position %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>

            <table id="table-management-shared" class="table-auto xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2 bg-blue-dark-200">
                <tr>
                  <th colspan="2" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Management Shares</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-sm">
                  <tr>
                    <td class="px-2 py-3 text-left"><%= @company_data.management_shares %></td>
                  </tr>
              </tbody>
            </table>

            <table id="table-shareholders-data" class="table-auto xl:place-self-start w-full h-max row-span-1">
              <thead class="p-2 bg-blue-dark-200">
                <tr>
                  <th colspan="2" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Securities and Shareholders Data</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-sm">
                <tr>
                  <td class="px-2 py-3 text-left"><b>Total Number Of Shareholders</b></td>
                  <td class="px-2 py-3 text-left"><%= @company_data.securities_and_shareholders_data.total_number_of_shareholders %></td>
                </tr>
                <tr>
                  <td class="px-2 py-3 text-left"><b>Number Of Shares Nominal Price</b></td>
                  <td class="px-2 py-3 text-left flex items-center">
                  <a href={@company_data.securities_and_shareholders_data.sase_url} target="_blank"
                    class="pr-2 text-blue-300"
                  >
                    <%= @company_data.symbol %>
                  </a>
                  <%= @company_data.securities_and_shareholders_data.number_of_shares_nominal_price %>
                  </td>
                </tr>
              </tbody>
            </table>

            <table id="table-top-10-owners" class="table-auto xl:justify-self-start w-full h-max row-span-3">
              <thead class="p-2 bg-blue-dark-200">
                <tr>
                  <th colspan="3" class="px-6 py-3 rounded-lg text-white text-sm uppercase ">Top 10 Owners</th>
                </tr>
              </thead>
              <tbody class="bg-gray-100 text-sm">
                <tr>
                  <td class="px-2 py-3 text-left"><b>Name</b></td>
                  <td class="px-2 py-3 text-left"><b>Percent</b></td>
                  <td class="px-2 py-3 text-left"><b>Date</b></td>
                 </tr>
                <%= for owner <- @company_data.top_10_owners do %>
                  <tr>
                    <td class="px-2 py-3 text-left"><%= owner["naziv"] %></td>
                    <td class="px-2 py-3 text-left"><%= owner["procenti"] %>%</td>
                    <td class="px-2 py-3 text-left"><%= format_date(owner["datum"]) %></td>
                  </tr>
                <% end %>
              </tbody>
            </table>
        </div>
      </section>
    """
  end
end
