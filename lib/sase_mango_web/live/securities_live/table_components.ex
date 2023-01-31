defmodule SaseMangoWeb.SecuritiesLive.TableComponents do
  @moduledoc """
  Module contains helper components used by the securities table
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

  def table_row(%{security: security} = assigns) do
    class =
      cond do
        security[:newest] ->
          "bg-[#E3F2FF]"

        security[:new] ->
          "bg-[#F8F9FA]"

        true ->
          ""
      end

    ~H"""
    <tr class={class} id={"security-" <> @security.symbol}>
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  def one_value_number_cell(assigns) do
    ~H"""
    <td class="text-right 2xl:text-xl p-2 2xl:px-4 2xl:py-2"><%= @value %></td>
    """
  end

  def double_value_number_cell(assigns) do
    special_sign = if(assigns[:procent], do: "%", else: "")

    ~H"""
    <td class="p-2 2xl:px-4 2xl:py-2">
      <div class="flex flex-col gap-4 text-right">
          <span><%= @first_value %><%= special_sign %></span>
          <span><%= @second_value %><%= special_sign %></span>
      </div>
    </td>
    """
  end

  defp get_icon_color(%{sort_by: sort_key} = sort_options, key) when sort_key == key do
    icon_color(sort_options.sort_order)
  end

  defp get_icon_color(_sort_options, _key), do: nil

  defp icon_color(:asc), do: "text-sort-asc"
  defp icon_color(:desc), do: "text-sort-desc"

  defp get_icon_direction(:number, %{sort_by: sort_key} = sort_options, key)
       when sort_key == key do
    get_icon_rotation(sort_options.sort_order)
  end

  defp get_icon_direction(_type, _sort_options, _key), do: nil

  defp get_icon_rotation(:asc), do: "rotate-down"
  defp get_icon_rotation(:desc), do: "rotate-up"
end
