defmodule SaseMangoWeb.Components.SortingComponent do
  use SaseMangoWeb, :live_component

  alias SaseMangoWeb.Components.TableIconsComponent

  def render(assigns) do
    ~H"""
      <div
        phx-click="sort_column"
        phx-target={@myself}
        class="sortable_column"
      >
        <span><%= @col_text %></span>

        <%= if @col_type == :text && @sort_options.sort_by == @key do %>
          <div class={"#{icon_color(@sort_options, @key)}"}>
            <%= if @sort_options.sort_order == :asc do %>
              <TableIconsComponent.text_sort_asc />
            <% else %>
              <TableIconsComponent.text_sort_desc />
            <% end %>
          </div>
        <% end %>

        <%= if @col_type == :text && @sort_options.sort_by != @key do %>
          <div>
            <TableIconsComponent.text_sort_asc />
          </div>
        <% end %>

        <%= if @col_type == :number do %>
          <div class={"#{icon_color(@sort_options, @key)}
                      #{icon_direction(@sort_options, @key)}"}>
            <TableIconsComponent.number_sort_icon />
          </div>
        <% end %>
      </div>
    """
  end

  def handle_event("sort_column", _params, socket) do
    %{sort_options: %{sort_order: sort_order}, key: key} = socket.assigns

    sort_order = if sort_order == :asc, do: :desc, else: :asc
    sort_options = %{sort_by: key, sort_order: sort_order}

    send(self(), {:url_update, sort_options})

    {:noreply, assign(socket, sort_options: sort_options)}
  end

  defp icon_color(sort_options, key) do
    if sort_options.sort_by == key do
      if sort_options.sort_order == :desc, do: "text-[#FF1010]", else: "text-[#15FF10]"
    else
      "text-white"
    end
  end

  defp icon_direction(sort_options, key) do
    if sort_options.sort_by == key do
      if sort_options.sort_order == :asc, do: "rotate-down", else: "rotate-up"
    end
  end
end
