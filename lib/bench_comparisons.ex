defmodule Aoc2024.Day06Fast do
  def part2() do
    "./day_6_input.txt"
    |> main()
    |> Enum.reduce(0, &(&2 + cycle_count(&1)))
  end

  def part2_async() do
    "./day_6_input.txt"
    |> main()
    |> Task.async_stream(&cycle_count/1, ordered: false)
    |> Enum.reduce(0, fn {:ok, num}, sum -> sum + num end)
  end

  def main(file) do
    rows =
      file
      |> File.read!()
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&String.to_charlist/1)

    n = length(rows)

    grid =
      for {row, i} <- Enum.with_index(rows, 1),
          {val, j} <- Enum.with_index(row, 1),
          into: %{},
          do: {{i, j}, val}

    h =
      for i <- 1..n, into: %{} do
        ranges =
          1..n
          |> Enum.filter(&(Map.get(grid, {i, &1}) == ?#))
          |> Enum.reduce([1..n], &ranges_split(&2, &1))

        {i, ranges}
      end

    v =
      for j <- 1..n, into: %{} do
        ranges =
          1..n
          |> Enum.filter(&(Map.get(grid, {&1, j}) == ?#))
          |> Enum.reduce([1..n], &ranges_split(&2, &1))

        {j, ranges}
      end

    ranges = {h, v}
    {position, direction} = Enum.find(grid, fn {_, val} -> val not in [?., ?#] end)

    path =
      steps(direction, position, ranges, grid)
      |> Stream.chunk_every(2, 1, :discard)
      |> Stream.flat_map(fn [{{a, b}, dir}, {{c, d}, _}] ->
        for i <- a..c, j <- b..d, do: {{i, j}, dir}
      end)

    grid = Map.put(grid, position, ?.)

    :persistent_term.put(__MODULE__, {grid, ranges})

    path
    |> Stream.uniq_by(&elem(&1, 0))
    |> Stream.chunk_every(2, 1, :discard)
  end

  def cycle_count([{turning, _}, {turning, _}]), do: 0

  def cycle_count([{prev_position, prev_direction}, {{i, j} = position, _}]) do
    {grid, {h, v}} = :persistent_term.get(__MODULE__)
    grid = Map.put(grid, position, ?#)

    ranges =
      {Map.update!(h, i, &ranges_split(&1, j)), Map.update!(v, j, &ranges_split(&1, i))}

    steps(prev_direction, prev_position, ranges, grid)
    |> Stream.drop(1)
    |> Enum.reduce_while(MapSet.new(), fn x, visited ->
      if MapSet.member?(visited, x) do
        {:halt, :cycle}
      else
        {:cont, MapSet.put(visited, x)}
      end
    end)
    |> case do
      :cycle -> 1
      _ -> 0
    end
  end

  def turn_90(?^), do: ?>
  def turn_90(?>), do: ?v
  def turn_90(?v), do: ?<
  def turn_90(?<), do: ?^

  def turn_270(?^), do: ?<
  def turn_270(?>), do: ?^
  def turn_270(?v), do: ?>
  def turn_270(?<), do: ?v

  def step(?^, {row, col}, i), do: {row - i, col}
  def step(?>, {row, col}, i), do: {row, col + i}
  def step(?v, {row, col}, i), do: {row + i, col}
  def step(?<, {row, col}, i), do: {row, col - i}

  def find_range(d, {i, j}, {ranges, _}) when d in [?<, ?>] do
    Enum.find(Map.get(ranges, i), fn range -> j in range end)
  end

  def find_range(d, {i, j}, {_, ranges}) when d in [?^, ?v] do
    Enum.find(Map.get(ranges, j), fn range -> i in range end)
  end

  def steps(direction0, position0, ranges, grid) do
    Stream.unfold({true, position0, direction0}, fn {cont?, {i, j} = curr, direction} ->
      if cont? do
        %{first: first, last: last} = find_range(direction, curr, ranges)

        next =
          case direction do
            ?^ -> {first, j}
            ?> -> {i, last}
            ?v -> {last, j}
            ?< -> {i, first}
          end

        prev_direction = turn_270(direction)

        {{curr, direction},
         {Map.has_key?(grid, step(prev_direction, curr, 1)), next, turn_90(direction)}}
      else
        nil
      end
    end)
  end

  def ranges_split(ranges, x) do
    {left, [range | right]} = Enum.split_while(ranges, &(x not in &1))
    left ++ range_split(range, x) ++ right
  end

  def range_split(a..c//1, a), do: [(a + 1)..c]
  def range_split(a..c//1, c), do: [a..(c - 1)]
  def range_split(a..c//1, b) when a < b and b < c, do: [a..(b - 1), (b + 1)..c]
end

# Lifted from others in order to compare
# https://elixirforum.com/t/advent-of-code-2024-day-4/67869/32

defmodule T do
  def p1(input) do
    field = parse_field(input)

    find_letters(?X, field)
    |> surrounded_by(?M, field)
    |> followed_by(?A, field)
    |> followed_by(?S, field)
    |> Enum.count()
  end

  defp parse_field(input) do
    width = :binary.match(input, "\n") |> elem(0)
    chars = :binary.replace(input, "\n", "", [:global])
    height = div(byte_size(chars), width)

    {width, height, chars}
  end

  defp find_letters(letter, {width, height, chars}) do
    chars
    |> :binary.matches(<<letter>>)
    |> Stream.map(fn {index, _} -> {rem(index, width), div(index, height)} end)
  end

  defp surrounded_by(matches, letter, {width, height, chars}) do
    x_range = 0..(width - 1)
    y_range = 0..(height - 1)

    Stream.flat_map(matches, fn {x, y} ->
      for dx <- -1..1,
          x2 = x + dx,
          x2 in x_range,
          dy <- -1..1,
          y2 = y + dy,
          y2 in y_range,
          :binary.at(chars, x2 + width * y2) == letter,
          do: {x2, y2, dx, dy}
    end)
  end

  defp followed_by(matches, letter, {width, height, chars}) do
    x_range = 0..(width - 1)
    y_range = 0..(height - 1)

    Stream.flat_map(matches, fn {x, y, dx, dy} ->
      x2 = x + dx
      y2 = y + dy

      if x2 in x_range and y2 in y_range and :binary.at(chars, x2 + width * y2) == letter do
        [{x2, y2, dx, dy}]
      else
        []
      end
    end)
  end
end

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
    grid = "./day_4_input.txt" |> File.read!() |> parse_input

    grid
    |> find_coords("X")
    |> Enum.flat_map(&find_xmas_words(grid, &1))
    |> length()
  end

  def part2() do
    grid = "./day_4_input.txt" |> File.read!() |> parse_input

    grid
    |> find_coords("A")
    |> Enum.flat_map(&find_x_mas_words(grid, &1))
    |> length()
  end

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

  defp find_x_mas_words(grid, start) do
    [[[{1, -1}, {1, 1}], [{-1, 1}, {-1, -1}]], [[{-1, -1}, {1, -1}], [{-1, 1}, {1, 1}]]]
    |> Enum.filter(fn [side1, side2] ->
      (Enum.all?(side1, &matches?(start, &1, 1, "M", grid)) &&
         Enum.all?(side2, &matches?(start, &1, 1, "S", grid))) ||
        (Enum.all?(side1, &matches?(start, &1, 1, "S", grid)) &&
           Enum.all?(side2, &matches?(start, &1, 1, "M", grid)))
    end)
  end

  def matches?({row1, col1}, {row2, col2}, offset, letter, grid) do
    Map.get(grid, {row1 + offset * row2, col1 + offset * col2}) == letter
  end

  def parse_input(input) do
    Advent.Grid.new(input)
  end

  # def part1_verify, do: input() |> parse_input() |> part1()
  # def part2_verify, do: input() |> parse_input() |> part2()
end
