defmodule SaseMangoWeb.SecuritiesLive.SortingComponent do
  @moduledoc """
  Component that renders table sort link
  """

  use SaseMangoWeb, :component

  alias SaseMangoWeb.SharedComponents.TableIconsComponent

  def sort_link(assigns) do
    ~H"""
      <div
        phx-click="sort_column"
        phx-value-key={@key}
        class="sortable-column 2xl:flex-row"
      >
        <span><%= @col_text %></span>

        <div class={"
            #{get_icon_color(@sort_options, @key)}
            #{get_icon_direction(@col_type, @sort_options, @key)}
          "}>
          <TableIconsComponent.sort_icon
            col_type={@col_type}
            sort_options={@sort_options.sort_order}
            key={@key}
           />
        </div>
      </div>
    """
  end

  defp get_icon_color(%{sort_by: sort_key} = sort_options, key) when sort_key == key do
    icon_color(sort_options.sort_order)
  end

  defp get_icon_color(_sort_options, _key), do: nil

  defp icon_color(:asc), do: "text-[#15FF10]"
  defp icon_color(:desc), do: "text-[#FF1010]"

  defp get_icon_direction(:number, %{sort_by: sort_key} = sort_options, key)
       when sort_key == key do
    get_icon_rotation(sort_options.sort_order)
  end

  defp get_icon_direction(_type, _sort_options, _key), do: nil

  defp get_icon_rotation(:asc), do: "rotate-down"
  defp get_icon_rotation(:desc), do: "rotate-up"
end
