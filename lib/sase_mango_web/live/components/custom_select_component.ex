defmodule SaseMangoWeb.Components.CustomSelectComponent do
  use SaseMangoWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class=""
    >
      <div class="relative mt-1">
        <div
          class="relative w-full px-[1rem] py-[0.9rem] text-left bg-white border border-gray-500 cursor-default rounded-[0.6rem] shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 text-[1em] font-[300]"
          x-ref="button"
          phx-click="toggle"
          phx-click-away="hide_select"
        >
          <span class="flex text-left items-center gap-2 mr-16 cursor-pointer">
          <%= if String.length(@selected_item.key) > 0 do %>
            <span class="block truncate text-[#5B92D7]"><%= @selected_item.key %></span>
            <span class="block truncate text-[#1E1E1E]"><%= @selected_item.value %></span>
          <% else %>
            <span class="block truncate text-[#B5B5B5] pr-8">SELECT</span>
          <% end %>
          </span>
          <span class="absolute cursor-pointer inset-y-0 right-0 flex items-center pr-4 ml-3">
            <svg width="15" height="8"
              viewBox="0 0 15 9"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path d="M1 1L7.08696 7L13 1" stroke="#9A9A9A" stroke-width="2" stroke-linecap="round"/>
            </svg>
          </span>
        </div>

        <%= if @open do %>
          <ul
              class={"absolute z-10 #{if String.length(@selected_item.key) > 0, do: "w-full", else: "w-max" } py-1 mt-1 overflow-y-auto text-[1em] font-[300] bg-white shadow-lg max-h-[30rem] rounded-lg ring-1 ring-black ring-opacity-5 focus:outline-none"}
              role="listbox"
            >
            <%= for option <- @options do %>
              <li
                class="relative cursor-default select-none"
                role="option"
              >
                <div class="flex flex-col gap-2 py-2 pl-3 pr-9 border-b border-gray-100 cursor-pointer hover:bg-sky-100"
                  phx-click="custom_select"
                  phx-value-symbol={option.key}
                >
                  <span class="block ml-3 font-normal text-[#5B92D7] truncate">
                    <%= option.key %>
                  </span>
                  <span class="block ml-3 font-normal text-[#1E1E1E] truncate">
                    <%= option.value %>
                  </span>
                </div>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>
      <%= hidden_input @f, @name, id: "symbol", value: @selected_item.key %>
    </div>
    """
  end
end
