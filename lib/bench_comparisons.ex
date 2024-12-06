# Lifted from others in order to compare
# https://elixirforum.com/t/advent-of-code-2024-day-4/67869/32
defmodule Advent.Grid do
  def new(input) do
    input
    |> String.split("\n", trim: true)
    |> Enum.with_index()
    |> Enum.reduce(Map.new(), &parse_row/2)
  end

  def size(grid) do
    coords = Map.keys(grid)
    {row, _} = Enum.max_by(coords, &elem(&1, 0))
    {_, col} = Enum.max_by(coords, &elem(&1, 1))

    {row, col}
  end

  def min(grid) do
    coords = Map.keys(grid)
    {row, _} = Enum.min_by(coords, &elem(&1, 0))
    {_, col} = Enum.min_by(coords, &elem(&1, 1))

    {row, col}
  end

  def corners(grid) do
    {min(grid), size(grid)}
  end

  defp parse_row({row, row_no}, map) do
    row
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.reduce(map, fn {col, col_no}, map ->
      Map.put(map, {row_no + 1, col_no + 1}, col)
    end)
  end

  def display(grid, highlight \\ []) do
    vertices = Map.keys(grid)
    {{min_row, min_col}, {max_row, max_col}} = Enum.min_max(vertices)

    for row <- min_row..max_row, col <- min_col..max_col do
      if val = highlight?(highlight, {row, col}) do
        val
      else
        value = Map.get(grid, {row, col}, " ")

        case value do
          x when is_list(x) ->
            if(length(x) > 1, do: "#{length(x)}", else: hd(x))

          x ->
            "#{x}"
        end
      end
    end
    |> Enum.chunk_every(max_col - min_col + 1)
    |> Enum.map(fn row ->
      row
      |> Enum.filter(& &1)
      |> List.to_string()
      |> IO.puts()
    end)

    grid
  end

  defp highlight?(list, coord) when is_list(list) do
    if coord in list, do: colour("x")
  end

  defp highlight?(%MapSet{} = mapset, coord) do
    if MapSet.member?(mapset, coord), do: colour("x")
  end

  defp highlight?(map, coord) when is_map(map) do
    if val = Map.get(map, coord), do: colour(val)
  end

  defp colour(char) do
    # Red stands out most against white, at small and large text sizes
    IO.ANSI.red() <> "#{char}" <> IO.ANSI.reset()
  end
end

defmodule Y2024.Day04 do
  # use Advent.Day, no: 04

  def part1() do
    grid = "./day_4_input.txt" |> File.read!() |>parse_input
    grid
    |> find_coords("X")
    |> Enum.flat_map(&find_xmas_words(grid, &1))
    |> length()
  end

  # def part2(input) do
  #   input
  #   |> find_coords("A")
  #   |> Enum.flat_map(&find_x_mas_words(input, &1))
  #   |> length()
  # end

  defp find_coords(grid, letter) do
    grid
    |> Enum.filter(fn {_coord, check} -> letter == check end)
    |> Enum.map(&elem(&1, 0))
  end

  defp find_xmas_words(grid, start) do
    # Words may spread out in any of the eight directions from the starting coord
    [{-1, 0}, {-1, 1}, {0, 1}, {1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, -1}]
    |> Enum.filter(fn next ->
      matches?(start, next, 1, "M", grid) &&
        matches?(start, next, 2, "A", grid) &&
        matches?(start, next, 3, "S", grid)
    end)
  end

  # defp find_x_mas_words(grid, start) do
  #   [[[{1, -1}, {1, 1}], [{-1, 1}, {-1, -1}]], [[{-1, -1}, {1, -1}], [{-1, 1}, {1, 1}]]]
  #   |> Enum.filter(fn [side1, side2] ->
  #     (Enum.all?(side1, &matches?(start, &1, 1, "M", grid)) &&
  #        Enum.all?(side2, &matches?(start, &1, 1, "S", grid))) ||
  #       (Enum.all?(side1, &matches?(start, &1, 1, "S", grid)) &&
  #          Enum.all?(side2, &matches?(start, &1, 1, "M", grid)))
  #   end)
  # end

  def matches?({row1, col1}, {row2, col2}, offset, letter, grid) do
    Map.get(grid, {row1 + offset * row2, col1 + offset * col2}) == letter
  end

  def parse_input(input) do
    Advent.Grid.new(input)
  end

  # def part1_verify, do: input() |> parse_input() |> part1()
  # def part2_verify, do: input() |> parse_input() |> part2()
end
