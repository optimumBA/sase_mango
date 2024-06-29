defmodule SaseMangoWeb.SecuritiesLive.TableComponents do
  @moduledoc """
  Module contains helper components used by the securities table
  """

  use SaseMangoWeb, :html

  alias SaseMangoWeb.SharedComponents.TableIconsComponent

  @doc """
  Shows the table sort component with column title and sort icon.

  ## Examples

      <th :for={table_column <- @table_columns}>
          ...
            <.sort_link column={table_column} sort_options={@sort_options} />
          ...
      </th>
  """
  attr :class, :string, default: nil
  attr :column, :map, required: true
  attr :sort_options, :map, required: true

  def sort_link(assigns) do
    ~H"""
    <div
      phx-click="sort_column"
      phx-value-col_name={@column.name}
      class={["sortable-column 2xl:flex-row", @class]}
    >
      <span><%= @column.title %></span>
      <div class={"
          #{get_icon_color(@sort_options, @column.name)}
          #{get_icon_direction(@column.type, @sort_options, @column.name)}
        "}>
        <TableIconsComponent.sort_icon
          col_type={@column.type}
          sort_options={@sort_options}
          key={@column.name}
        />
      </div>
    </div>
    """
  end

  @doc """
  Renders the table row for securities with content as a slot.

  ## Examples

      <%= for security <- @securities do %>
        <.table_row security={security} >
            <td class="...">
              ...
            </td>
            ...
        </.table_row>
      <% end %>
  """
  attr :class, :string, default: nil
  slot :inner_block, required: true
  attr :security, :map, required: true

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

    assigns = assign(assigns, :class, class)

    ~H"""
    <tr class={@class} id={"security-" <> @security.symbol}>
      <%= render_slot(@inner_block) %>
    </tr>
    """
  end

  @doc """
  Renders the table number cell component for one value.

  ## Examples

      <.one_value_number_cell class="text-right ..." value={price} round={2} />
  """
  attr :class, :string
  attr :delimiter, :string
  attr :percentage, :boolean, default: false
  attr :round, :integer
  attr :separator, :string
  attr :suffix, :string, default: nil
  attr :value, :float, required: true

  def one_value_number_cell(assigns) do
    maybe_add_percentage = maybe_add_percentage(assigns[:percentage])

    format_value =
      assigns.value
      |> maybe_round_value(assigns[:round])
      |> maybe_format_with_delimiter(assigns[:delimiter], assigns[:separator])

    assigns =
      assigns
      |> assign(:value, format_value)
      |> assign(:maybe_add_percentage, maybe_add_percentage)
      |> assign_new(:class, fn -> "text-center" end)

    ~H"""
    <td class={@class}>
      <%= @value %><%= @suffix %><%= @maybe_add_percentage %>
    </td>
    """
  end

  @doc """
  Renders the table number cell component for two values.

  ## Examples

      <.double_value_number_cell class="text-right ..." first_value={ask_price} second_value={ask_volume} round_first={2}/>
  """
  attr :class, :string
  attr :delimiter, :string
  attr :first_value, :float, required: true
  attr :percentage, :boolean, default: false
  attr :round_first, :integer
  attr :round_second, :integer
  attr :second_value, :float, required: true
  attr :separator, :string

  def double_value_number_cell(assigns) do
    maybe_add_percentage = maybe_add_percentage(assigns[:percentage])

    format_first_value =
      assigns.first_value
      |> maybe_round_value(assigns[:round_first])
      |> maybe_format_with_delimiter(assigns[:delimiter], assigns[:separator])

    format_second_value =
      assigns.second_value
      |> maybe_round_value(assigns[:round_second])
      |> maybe_format_with_delimiter(assigns[:delimiter], assigns[:separator])

    assigns =
      assigns
      |> assign(:maybe_add_percentage, maybe_add_percentage)
      |> assign(:first_value, format_first_value)
      |> assign(:second_value, format_second_value)
      |> assign_new(:class, fn -> "text-center" end)

    ~H"""
    <td class="p-2 2xl:px-4 2xl:py-2">
      <div class={@class}>
        <span><%= @first_value %><%= @maybe_add_percentage %></span>
        <span><%= @second_value %><%= @maybe_add_percentage %></span>
      </div>
    </td>
    """
  end

  defp maybe_round_value(value, nil), do: value
  defp maybe_round_value(value, round), do: Decimal.round(value, round)

  defp maybe_add_percentage(false), do: ""
  defp maybe_add_percentage(true), do: "%"

  defp maybe_format_with_delimiter(value, nil, nil), do: value

  defp maybe_format_with_delimiter(value, delimiter, separator) do
    Number.Delimit.number_to_delimited(value, delimiter: delimiter, separator: separator)
  end

  defp get_icon_color(%{sort_by: sort_key} = sort_options, key) when sort_key == key do
    icon_color(sort_options.sort_order)
  end

  defp get_icon_color(_sort_options, _key), do: nil

  defp icon_color(:asc), do: "text-green-350"
  defp icon_color(:desc), do: "text-red-550"

  defp get_icon_direction(:number, %{sort_by: sort_key} = sort_options, key)
       when sort_key == key do
    get_icon_rotation(sort_options.sort_order)
  end

  defp get_icon_direction(_type, _sort_options, _key), do: nil

  defp get_icon_rotation(:asc), do: "rotate-down"
  defp get_icon_rotation(:desc), do: "rotate-up"
end
