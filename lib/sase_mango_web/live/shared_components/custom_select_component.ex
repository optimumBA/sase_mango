defmodule SaseMangoWeb.SharedComponents.CustomSelectComponent do
  use SaseMangoWeb, :live_component

  @impl true
  def update(assigns, socket) do
    %{options: options} = assigns

    socket =
      socket
      |> assign(:suggestions, options)
      |> assign(:suggested_element, "")
      |> assign(assigns)

    {:ok, socket}
  end

  @impl true
  def handle_event("select_input_changed", %{"key" => key, "value" => value} = _params, socket) do
    %{options: options_from_socket} = socket.assigns

    case key do
      "Enter" ->
        if String.length(value) > 0, do: send(self(), {:update_state, value})

        {:noreply, socket}

      _other ->
        filtered_options =
          Enum.filter(options_from_socket, fn opt ->
            String.starts_with?(opt.key, value) || String.starts_with?(opt.value, value)
          end)

        suggested_element =
          if length(filtered_options) > 0 do
            f_element = List.first(filtered_options)

            is_suggested_by_symbol? = String.starts_with?(f_element.key, value)

            if is_suggested_by_symbol?, do: f_element.key, else: f_element.value
          end

        if String.length(value) > 0, do: send(self(), {:update_state})

        {
          :noreply,
          socket
          |> assign(:suggested_element, suggested_element)
          |> assign(:suggestions, filtered_options)
        }
    end
  end

  def handle_event("select_input_changed", _params, socket), do: {:noreply, socket}

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class=""
    >
      <div class="relative mt-1">
        <div
          class="relative cursor-pointer w-full sm:min-w-[380px] w-full px-[1rem] py-0 text-left bg-white border border-[#979797] hover:border-[#565555] rounded-[0.6rem] shadow-sm focus:outline-none focus:ring-1 focus:ring-indigo-500 focus:border-indigo-500 text-[1em] font-[300]"
          phx-click-away="hide_select"
          phx-click="toggle"
        >
            <%= if @input_flip do %>
              <div id="input-cover" class="absolute z-[10] bg-white flex items-center gap-2 text-left py-[0.9rem] mr-16"
              phx-hook="FieldReset"

              >
                <span class="block truncate text-[#5B92D7]"><%= @selected_item.key %></span>
                <span class="block truncate text-[#1E1E1E]"><%= @selected_item.value %></span>
              </div>
            <% end %>
            <div class="relative">
              <input
                autocomplete="off"
                id="select-field"
                type="text"
                placeholder="SELECT"
                class="border-0 p-[1rem] tracking-normal bg-transparent text-[1.2em] font-[300] pr-8 placeholder:focus:text-transparent"
                phx-keyup="select_input_changed"

                phx-target={@myself}
              />
              </div>

              <span class={"absolute #{if @suggested_element, do: "opacity-60", else: "opacity-0" } top-1/2 -translate-y-1/2 pl-[1rem] tracking-normal text-[1.2em] font-[300] text-[#a3a3a3]"} >
                <%= @suggested_element %>
              </span>

          <span class="absolute inset-y-0 right-0 flex items-center pr-4 ml-3">
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
              class={"absolute z-[10] sm:min-w-[380px] py-1 mt-2 overflow-y-auto text-[1em] font-[300] max-h-[34rem] bg-white drop-shadow-lg rounded-lg ring-2 ring-black ring-opacity-5 focus:outline-none"}
              role="selectable-options"
            >
            <%= for option <- @suggestions do %>
              <li
                class="relative select-none"
                role="option"
              >
                <div class="w-full flex flex-col gap-2 py-2 pl-3 pr-9 border-b border-gray-100 cursor-pointer hover:bg-sky-100"
                  phx-click="custom_select"
                  phx-value-symbol={option.key}
                >
                  <span class="block ml-3 font-normal text-[#5B92D7]">
                    <%= option.key %>
                  </span>
                  <span class="w-max block ml-3 font-normal text-[#1E1E1E]">
                    <%= option.value %>
                  </span>
                </div>
              </li>
            <% end %>
          </ul>
        <% end %>
      </div>
    </div>
    """
  end
end
