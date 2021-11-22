defmodule SaseMango.PlainTextTableRenderer do
  def render(table) do
    header = Keyword.get(table, :header, [])
    columns = Keyword.keys(header)
    rows = Keyword.get(table, :rows, [])

    max_widths =
      rows
      |> Enum.concat()
      |> Enum.concat([header])
      |> Enum.reduce([], fn row, acc ->
        row
        |> Enum.reduce(acc, fn {column, cell}, acc ->
          cell_width = String.length(cell) + 2

          max_width =
            case Keyword.fetch(acc, column) do
              {:ok, max_width} ->
                if(cell_width > max_width, do: cell_width, else: max_width)

              :error ->
                cell_width
            end

          Keyword.put(acc, column, max_width)
        end)
      end)

    borders =
      columns
      |> Enum.map(&String.duplicate("-", Keyword.get(max_widths, &1)))
      |> Enum.join("+")

    borders_row = "+" <> borders <> "+\n"

    header = render_row(header, columns, max_widths)

    body =
      rows
      |> Enum.map(fn issuer_rows ->
        issuer_rows
        |> Enum.map(&render_row(&1, columns, max_widths))
        |> Enum.join()
      end)
      |> Enum.join(borders_row)

    borders_row <> header <> borders_row <> body <> borders_row
  end

  defp render_row(row, columns, max_widths) do
    result =
      columns
      |> Enum.map(fn column ->
        cell = Keyword.get(row, column, "")
        width = Keyword.get(max_widths, column)
        whitespace_width = width - String.length(cell)

        String.duplicate(" ", floor(whitespace_width / 2)) <>
          cell <> String.duplicate(" ", ceil(whitespace_width / 2))
      end)
      |> Enum.join("|")

    "|" <> result <> "|\n"
  end
end
