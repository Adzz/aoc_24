defmodule Aoc24 do
  @moduledoc """
  Documentation for `Aoc24`.
  """

  @doc """
  Total the difference between the two numbers in the sorted lists.
  """
  def day_1_1() do
    {left, right} = parse(File.read!("./input_day_1.txt"), {[], []})

    Enum.zip_reduce(Enum.sort(left), Enum.sort(right), 0, fn left, right, acc ->
      abs(left - right) + acc
    end)
  end

  @doc """
  Count how many times the numbers in the left list appear in the right list.
  """
  def day_1_2() do
    {left, right} = parse(File.read!("./input_day_1.txt"), {[], []})
    frequencies = Enum.frequencies(right)

    Enum.reduce(left, 0, fn number, score ->
      number * Map.get(frequencies, number, 0) + score
    end)
  end

  @new_line "\n"
  @spaces "   "
  # ERL_COMPILER_OPTIONS=bin_opt_info mix compile --force
  defp parse(<<>>, acc), do: acc

  defp parse(
         <<first::binary-size(5), @spaces, second::binary-size(5), @new_line, rest::binary>>,
         {left, right}
       ) do
    first_number = String.to_integer(first)
    second_number = String.to_integer(second)
    parse(rest, {[first_number | left], [second_number | right]})
  end

  @doc """
  Lines have to:

    - Always increase or decrease
    - Never change by more than 3, always by at least 1

  Return the number of lines that do that. There is the simple way. I wonder if there is
  a more convoluted slower way.

  Traverse in pairs. Each first number narrows down the possibility of valid next numbers
  which is kinda neat. Eg

    - First number == 75
    - Next number can ONLY be one of [76, 77, 78, 74, 73, 72]
  """
  def day_2_1() do
    "./day_2_1_input.txt"
    |> File.read!()
    |> String.split(@new_line, trim: true)
    |> Enum.reduce(0, fn line, count ->
      [one, two | rest] = line |> String.split(" ")
      one = String.to_integer(one)
      two = String.to_integer(two)
      diff = abs(one - two)

      if diff > 0 && diff < 4 do
        sum_safe_reports([two | rest], one < two, count)
      else
        count
      end
    end)
  end

  defp sum_safe_reports([_final], _, count), do: count + 1

  defp sum_safe_reports([current, next | rest], incrementing?, count) do
    next = String.to_integer(next)

    diff = if incrementing?, do: next - current, else: current - next

    if diff > 0 && diff < 4 do
      sum_safe_reports([next | rest], incrementing?, count)
    else
      count
    end
  end

  @doc """
  Same as 1 but now you can tolerate 1 rule violation per report. Turning a bool into an
  int? If there are > 1 errors then certainly removing one wont fix it. But if there is
  only one error then perhaps it's fixable. So we could just collect those one error
  problems and assess each in turn maybe.

  A better way is if you meet a problem, expand the window. that way you can skip the one
  in the middle. You still need to know how often to do that though I suppose, as you can
  only do that once.

  Count errors. Fix by getting a window of 3 and removing the middle always. Special case
  the first and maybe the end of the list.

  Problematic inputs:

      62 61 62 63 65 67 68 71
      91 89 88 87 82 80 78 73
      41 42 40 37 37 35 33 26
      43 44 51 53 59
      64 61 54 51 50 47 45 38
      77 78 77 74 74 72 65
      86 84 81 84 79
      85 85 82 80 79 78 76
      66 66 65 62 62 60 56
  """
  def day_2_2() do
    "./day_2_1_input.txt"
    # "./example.txt"
    |> File.read!()
    |> String.split(@new_line, trim: true)
    |> Enum.reduce(0, fn line, count ->
      [one, two, three | rest] =
        line |> String.split(" ") |> Enum.map(&String.to_integer/1)

      # The special case here is that you have to start one of three ways. You can begin
      # with any of them successfully but if you ever see > 1 error halt immediately and
      # try one of the other possible starts. This list enumerates each possible start
      possible_starting_combos = [
        {one, two, [two, three | rest], 0},
        # These two start with 1 error because in both cases we have already dropped a number.
        {one, three, [three | rest], 1},
        {two, three, [three | rest], 1}
      ]

      start_with_pair(possible_starting_combos, count)
    end)
  end

  defp start_with_pair([], count), do: count

  defp start_with_pair([{left, right, rest, errors} | next_iteration], count) do
    new_count =
      if is_safe?(left, right, left < right) do
        sum_safe_reports(rest, left < right, errors, count)
      else
        count
      end

    if count == new_count do
      start_with_pair(next_iteration, count)
    else
      new_count
    end
  end

  defp is_safe?(first, next, incrementing?) do
    diff = if incrementing?, do: next - first, else: first - next
    diff > 0 && diff < 4
  end

  defp sum_safe_reports([_final], _, _, count), do: count + 1

  defp sum_safe_reports([penultimate, final], incrementing?, errors, count) do
    # If we have 0 errors then we can always fix when there are 2 numbers left.
    if errors < 1 || is_safe?(penultimate, final, incrementing?) do
      count + 1
    else
      count
    end
  end

  defp sum_safe_reports([one, two, three | rest], incrementing?, errors, count) do
    if is_safe?(one, two, incrementing?) do
      sum_safe_reports([two, three | rest], incrementing?, errors, count)
    else
      errors = errors + 1

      if is_safe?(one, three, incrementing?) && errors < 2 do
        sum_safe_reports([three | rest], incrementing?, errors, count)
      else
        count
      end
    end
  end

  @doc """
  Basically parse out the MUL instructions and add them up.

  178794710 was our answer.
  """
  def day_3_1() do
    "./day_3_input.txt"
    |> File.read!()
    |> parse(1, [], 0)
  end

  def parse(<<>>, _, _, total), do: total

  @mul_start "mul("
  @comma ","
  @mul_end ")"
  # If we see a mul start but the stack is not empty then it can't be valid.
  def parse(<<@mul_start, rest::binary>>, current_index, [], total) do
    new_current_index = current_index + 3
    end_index = parse_number(rest, new_current_index)

    if end_index == new_current_index do
      parse(rest, end_index, [], total)
    else
      <<number::binary-size(end_index - new_current_index), rest::binary>> = rest
      first_int = String.to_integer(number)
      parse(rest, end_index, [first_int], total)
    end
  end

  def parse(<<@comma, rest::binary>>, current_index, [first_int], total) do
    new_current_index = current_index + 1
    end_index = parse_number(rest, new_current_index)

    if end_index == new_current_index do
      parse(rest, current_index, [], total)
    else
      <<number::binary-size(end_index - new_current_index), rest::binary>> = rest
      second_int = String.to_integer(number)
      parse(rest, end_index, [second_int, first_int], total)
    end
  end

  def parse(<<@mul_end, rest::binary>>, current_index, [first, second], total) do
    parse(rest, current_index + 1, [], first * second + total)
  end

  # We reset the stack if we had started a mult that never happened.
  def parse(<<_::binary-size(1), rest::binary>>, index, _stack, total) do
    parse(rest, index + 1, [], total)
  end

  @all_digits ~c"0123456789"
  for digit <- @all_digits do
    def parse_number(<<unquote(digit), rest::bits>>, end_index) do
      parse_number(rest, end_index + 1)
    end
  end

  def parse_number(_rest, end_index), do: end_index

  @doc """
  Adds more instructions basically, we bracket the dos / donts.

  Answer was 76729637.
  """
  def day_3_2() do
    "./day_3_input.txt"
    |> File.read!()
    |> parse_instructions(1, [], 0)
  end

  def parse_instructions(<<>>, _, _, total), do: total

  @doo "do()"
  @dont "don't()"
  def parse_instructions(<<@dont, rest::binary>>, current_index, _, total) do
    parse_instructions(rest, current_index + 6, [:dont], total)
  end

  def parse_instructions(<<@doo, rest::binary>>, current_index, [:dont], total) do
    parse_instructions(rest, current_index + 3, [], total)
  end

  # Now if the stack has :dont in it we skip.
  def parse_instructions(<<_::binary-size(1), rest::binary>>, current_index, [:dont], total) do
    parse_instructions(rest, current_index + 1, [:dont], total)
  end

  def parse_instructions(<<@mul_start, rest::binary>>, current_index, [], total) do
    new_current_index = current_index + 3
    end_index = parse_number(rest, new_current_index)

    if end_index == new_current_index do
      parse_instructions(rest, end_index, [], total)
    else
      <<number::binary-size(end_index - new_current_index), rest::binary>> = rest
      first_int = String.to_integer(number)
      parse_instructions(rest, end_index, [first_int], total)
    end
  end

  def parse_instructions(<<@comma, rest::binary>>, current_index, [first_int], total) do
    new_current_index = current_index + 1
    end_index = parse_number(rest, new_current_index)

    if end_index == new_current_index do
      parse_instructions(rest, current_index, [], total)
    else
      <<number::binary-size(end_index - new_current_index), rest::binary>> = rest
      second_int = String.to_integer(number)
      parse_instructions(rest, end_index, [second_int, first_int], total)
    end
  end

  def parse_instructions(<<@mul_end, rest::binary>>, current_index, [first, second], total) do
    parse_instructions(rest, current_index + 1, [], first * second + total)
  end

  def parse_instructions(<<_::binary-size(1), rest::binary>>, index, _stack, total) do
    parse_instructions(rest, index + 1, [], total)
  end

  @doc """
  This is like a word search but on steroids words can appear in any order and direction
  and can overlap. The approach we took was to create a binary of the rows, columns then
  each diagonal. Once we have the binary in whichever shape we want we check for XMAS and
  SAMX to handle both directions.

  For rows we do nothing as the puzzle input is already row major. To get columns we iterate
  over the binary in a way that lands us on the correct next character for the column.

  We do a similar thing for diagonals, but first generate the list of indexes into the
  square grid that would describe each row if it were a row of diagonals. Then we extract
  the characters from the original binary by converting those x/y coords into character byte
  positions and using :binary_part.

  For diagonals you can trim the first and last 3 rows because you can't make a long enough
  diagonal for there to be a match. In reality this is a very tiny optimization.

  Example problem with an answer of 18:

      MMMSXXMASM
      MSAMXMSMSA
      AMXSXMAAMM
      MSAMASMSMX
      XMASAMXAMM
      XXAMMXXAMA
      SMSMSASXSS
      SAXAMASAAA
      MAMMMXMMMM
      MXMXAXMASX

  2543 is the answer
  """
  def day4_1() do
    grid = "./day_4_input.txt" |> File.read!()

    line_length = line_length(grid, 0)
    row_count = check_line(grid, 0)
    ne_count = north_east_diagonal(grid, line_length)
    se_count = south_east_diagonal(grid, line_length)
    column_count = column_count(grid, line_length)
    row_count + ne_count + se_count + column_count
  end

  @samx "SAMX"
  @xmas "XMAS"
  @new_line "\n"
  defp check_line(<<>>, hits), do: hits

  defp check_line(<<@samx, _::binary>> = line, hits) do
    <<_::binary-size(3), rest::binary>> = line
    check_line(rest, hits + 1)
  end

  defp check_line(<<@xmas, _::binary>> = line, hits) do
    <<_::binary-size(3), rest::binary>> = line
    check_line(rest, hits + 1)
  end

  defp check_line(<<_::binary-size(1), rest::binary>>, hits), do: check_line(rest, hits)

  # We include the new line in the count because it makes the rest of the stuff work better
  defp line_length(<<@new_line, _::binary>>, count), do: count + 1
  defp line_length(<<_::binary-size(1), rest::binary>>, count), do: line_length(rest, count + 1)

  def column_count(grid, line_length) do
    Enum.reduce(0..(line_length - 1), "", fn x, lines ->
      columns({x, line_length - 2}, grid, line_length, lines)
    end)
    |> check_line(0)
  end

  def columns({_, y}, _, _, acc) when y < 0, do: <<acc::binary, @new_line>>

  def columns({x, y}, grid, line_length, acc) do
    char = :binary.part(grid, x + y * line_length, 1)
    columns({x, y - 1}, grid, line_length, <<acc::binary, char::binary>>)
  end

  def south_east_diagonal(grid, line_length) do
    se_diagonal_index({line_length - 2, 0}, line_length - 2, [])
    |> Enum.reduce("", fn diagonal_indexes, acc ->
      line =
        diagonal_indexes
        |> Enum.reduce("", fn {x, y}, acc ->
          char = :binary.part(grid, x + y * line_length, 1)
          <<acc::binary, char::binary>>
        end)

      <<acc::binary, line::binary, @new_line>>
    end)
    |> check_line(0)
  end

  # We've gone past bottom left.
  def se_diagonal_index({0, y}, last_idx, acc) when y == last_idx, do: acc

  # This is the first case hit - the top right
  def se_diagonal_index({last_idx, 0}, last_idx, acc) do
    se_diagonal_index({last_idx - 1, 0}, last_idx, [[{last_idx, 0}] | acc])
  end

  # This is the switch up case, where we round the corner on the top left hand side going down
  def se_diagonal_index({x, _}, last_idx, acc) when x < 0 do
    se_diagonal_index({0, 1}, last_idx, acc)
  end

  # this is going along the top row, we heading backwards on the x axis
  def se_diagonal_index({x, 0} = current_cell, last_idx, acc) do
    diagonal = [
      current_cell | Enum.map(1..(last_idx - x), fn y_coord -> {x + 1 * y_coord, y_coord} end)
    ]

    se_diagonal_index({x - 1, 0}, last_idx, [diagonal | acc])
  end

  # this is going down the leftmost column.
  def se_diagonal_index({0, y} = current, last_idx, acc) do
    diagonal = [current | Enum.map(1..(last_idx - y), fn y_coord -> {y_coord, y + y_coord} end)]
    se_diagonal_index({0, y + 1}, last_idx, [diagonal | acc])
  end

  def north_east_diagonal(grid, line_length) do
    # It's - 2, 1 because of the newline char at the end of each line 1 because of the 0 index
    # We start at X of 2 because first few rows can never match as they are too short.
    ne_diagonal_idx({0, 0}, line_length - 2, [])
    |> Enum.reduce("", fn diagonal_indexes, acc ->
      line =
        diagonal_indexes
        |> Enum.reduce("", fn {x, y}, acc ->
          char = :binary.part(grid, x + y * line_length, 1)
          <<acc::binary, char::binary>>
        end)

      <<acc::binary, line::binary, @new_line>>
    end)
    |> check_line(0)
  end

  def ne_diagonal_idx({last_idx, y}, last_idx, acc) when y >= last_idx, do: acc

  def ne_diagonal_idx({0, 0}, last_idx, acc) do
    ne_diagonal_idx({1, 0}, last_idx, [[{0, 0}] | acc])
  end

  def ne_diagonal_idx({x, 0}, last_idx, acc) when x > last_idx do
    ne_diagonal_idx({x - 1, 1}, last_idx, acc)
  end

  def ne_diagonal_idx({x, 0} = current_cell, last_idx, acc) do
    diagonal = [current_cell | Enum.map(1..x, fn y_coord -> {x - 1 * y_coord, y_coord} end)]
    ne_diagonal_idx({x + 1, 0}, last_idx, [diagonal | acc])
  end

  def ne_diagonal_idx({x, y} = current, last_idx, acc) do
    diagonal = [
      current | Enum.map(1..(last_idx - y), fn y_coord -> {x - 1 * y_coord, y + y_coord} end)
    ]

    ne_diagonal_idx({x, y + 1}, last_idx, [diagonal | acc])
  end
end
