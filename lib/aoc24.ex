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

  defp column_count(grid, line_length) do
    Enum.reduce(0..(line_length - 1), "", fn x, lines ->
      columns({x, line_length - 2}, grid, line_length, lines)
    end)
    |> check_line(0)
  end

  defp columns({_, y}, _, _, acc) when y < 0, do: <<acc::binary, @new_line>>

  defp columns({x, y}, grid, line_length, acc) do
    char = :binary.part(grid, x + y * line_length, 1)
    columns({x, y - 1}, grid, line_length, <<acc::binary, char::binary>>)
  end

  defp south_east_diagonal(grid, line_length) do
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
  defp se_diagonal_index({0, y}, last_idx, acc) when y == last_idx, do: acc

  # This is the first case hit - the top right
  defp se_diagonal_index({last_idx, 0}, last_idx, acc) do
    se_diagonal_index({last_idx - 1, 0}, last_idx, [[{last_idx, 0}] | acc])
  end

  # This is the switch up case, where we round the corner on the top left hand side going down
  defp se_diagonal_index({x, _}, last_idx, acc) when x < 0 do
    se_diagonal_index({0, 1}, last_idx, acc)
  end

  # this is going along the top row, we heading backwards on the x axis
  defp se_diagonal_index({x, 0} = current_cell, last_idx, acc) do
    diagonal = [
      current_cell | Enum.map(1..(last_idx - x), fn y_coord -> {x + 1 * y_coord, y_coord} end)
    ]

    se_diagonal_index({x - 1, 0}, last_idx, [diagonal | acc])
  end

  # this is going down the leftmost column.
  defp se_diagonal_index({0, y} = current, last_idx, acc) do
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

  defp ne_diagonal_idx({last_idx, y}, last_idx, acc) when y >= last_idx, do: acc

  defp ne_diagonal_idx({0, 0}, last_idx, acc) do
    ne_diagonal_idx({1, 0}, last_idx, [[{0, 0}] | acc])
  end

  defp ne_diagonal_idx({x, 0}, last_idx, acc) when x > last_idx do
    ne_diagonal_idx({x - 1, 1}, last_idx, acc)
  end

  defp ne_diagonal_idx({x, 0} = current_cell, last_idx, acc) do
    diagonal = [current_cell | Enum.map(1..x, fn y_coord -> {x - 1 * y_coord, y_coord} end)]
    ne_diagonal_idx({x + 1, 0}, last_idx, [diagonal | acc])
  end

  defp ne_diagonal_idx({x, y} = current, last_idx, acc) do
    diagonal = [
      current | Enum.map(1..(last_idx - y), fn y_coord -> {x - 1 * y_coord, y + y_coord} end)
    ]

    ne_diagonal_idx({x, y + 1}, last_idx, [diagonal | acc])
  end

  @doc """
  This one is about finding a diagonal MASs. Essentially we need to iterate over each letter
  and check if there is an A diagonally down from it. We can stop 3 from the end as the
  check on that letter is the same as the check on the last letter, and the check on the
  penultimate letter in a row would extend outside of the row, so can never work.

  If we find an A we can keep checking down and right again for the correct letter (which
  depends on the first letter seen), and then check + 2 down and to the left twice. Not
  actually too mental but we should keep checking on the binary too as it's fast.

    .M.S......
    ..A..MSMS.
    .M.S.MAA..
    ..A.ASMSM.
    .M.S.M....
    ..........
    S.S.S.S.S.
    .A.A.A.A..
    M.M.M.M.M.
    ..........

  Example grid should be 9.
  Answer was 1930.
  """
  def day4_2() do
    grid = "./day_4_input.txt" |> File.read!()
    line_length = line_length(grid, 0)
    find_x(grid, {0, 0}, line_length, 0)
  end

  @m "M"
  @a "A"
  @s "S"

  def find_x(binary, {x, y}, line_length, count) do
    if mas_se?(binary, line_length) || sam_se?(binary, line_length) do
      <<_::binary-size(2), rest::binary>> = binary

      count =
        if mas_sw?(rest, line_length) || sam_sw?(rest, line_length) do
          count + 1
        else
          count
        end

      next(binary, {x, y}, line_length, count)
    else
      next(binary, {x, y}, line_length, count)
    end
  end

  # This bounds check essentially.
  def next(binary, {x, y}, line_length, count) do
    if x + 1 > line_length - 4 do
      if y + 1 > line_length - 4 do
        # We stop because we are at max Y depth
        count
      else
        # Skip to next row
        <<_::binary-size(line_length - x), rest::binary>> = binary
        find_x(rest, {0, y + 1}, line_length, count)
      end
    else
      # Move right
      <<_::binary-size(1), rest::binary>> = binary
      find_x(rest, {x + 1, y}, line_length, count)
    end
  end

  def mas_se?(<<@m, rest::binary>>, line_length) do
    case southeast_once(rest, line_length) do
      <<@a, after_a::binary>> -> match?(<<@s, _::binary>>, southeast_once(after_a, line_length))
      _ -> false
    end
  end

  def mas_se?(_, _), do: false

  def sam_se?(<<@s, rest::binary>>, line_length) do
    case southeast_once(rest, line_length) do
      <<@a, after_a::binary>> -> match?(<<@m, _::binary>>, southeast_once(after_a, line_length))
      _ -> false
    end
  end

  def sam_se?(_, _), do: false

  def mas_sw?(<<@m, rest::binary>>, line_length) do
    case southwest_once(rest, line_length) do
      <<@a, after_a::binary>> -> match?(<<@s, _::binary>>, southwest_once(after_a, line_length))
      _ -> false
    end
  end

  def mas_sw?(_, _), do: false

  def sam_sw?(<<@s, rest::binary>>, line_length) do
    case southwest_once(rest, line_length) do
      <<@a, after_a::binary>> -> match?(<<@m, _::binary>>, southwest_once(after_a, line_length))
      _ -> false
    end
  end

  def sam_sw?(_, _), do: false

  def southwest_once(binary, line_length) do
    skip = line_length - 2
    <<_::binary-size(skip), rest::binary>> = binary
    rest
  end

  # May need bounds checks? so we don't wrap the line? Or handle higher up. But there is
  # a max X coord of line_length - 4, one for new line, one for last char and one for pen char and one to 0 index.
  def southeast_once(binary, line_length) do
    skip = line_length
    <<_::binary-size(skip), rest::binary>> = binary
    rest
  end

  @doc """
  We have ordering rules, and things to print or something:

      47|53
      97|13
      97|61
      97|47
      75|29
      61|13
      75|53
      29|13
      97|29
      53|29
      61|53
      97|53
      61|29
      47|13
      75|47
      97|75
      47|61
      75|61
      47|29
      75|13
      53|13

      75,47,61,53,29
      97,61,53,29,13
      75,29,13
      75,97,47,61,53
      61,13,29
      97,13,75,29,47


  Left of | must come before right. We must ID all updates which obey those rules. Some rules
  are for numbers not mentioned in the update, those rules get ignored of course.

  We have to find all updates that obey the rules, find the middle number and sum them.

  Think rough approach is to make a map of the sort order, eg:
  %{
   "47" => 0,
   "53 => 1,
   ...
  }

  and then use that when sorting the inputs. Not sure if there are multiple ways to satisfy
  the rules and if so whether sorting the inputs and checking that it's equal to the pre-sorted
  list is valid?

  One idea is work out how many unique numbers there are in the rules (simple guess is rules * 2)
  then like create a tuple of that many elements. Then swap shit around in that tuple, essentially
  implementing a sort of kinds.

  "happened before" is sounding very CRDT tho. Maybe the rules form some sort of hierarchy because
  previous rules influence latter ones. EG 2 before 3 and 1 before 2, must mean 1 before 3?
  Like the first line, 75 is before 47 and 61 and 53.

  I guess you could go along the line and say "find me all relevant rules for this one", eg
  75, comes_before: [29,53,47,61,13], comes_after: [97]

  Now when we traverse the line we just go, find all numbers after 75, are any of
  them in the "before" list. Then the same for after. Obvs some have none before some have none
  after.

  Answer was 4281 in the end
  """
  def day_5_1() do
    input = File.read!("./day_5_input.txt")
    {rules, reports} = rules_reports(input, [])

    rules = numbers_in_rules(rules)

    Enum.reduce(reports, 0, fn report, mid_number_sum ->
      report_good? =
        Enum.all?(report, fn number ->
          {must_come_before, must_come_after} = Map.fetch!(rules, number)
          {comes_after, comes_before} = numbers_before(number, report)

          (comes_after == [] || not Enum.any?(comes_after, &(&1 in must_come_before))) &&
            (comes_before == [] || not Enum.all?(comes_before, &(&1 in must_come_after)))
        end)

      if report_good? do
        mid = Enum.at(report, div(length(report), 2))
        mid_number_sum + mid
      else
        mid_number_sum
      end
    end)
  end

  defp comes_before(number, rules), do: for({^number, rule} <- rules, do: rule)
  defp comes_after(number, rules), do: for({rule, ^number} <- rules, do: rule)

  defp numbers_in_rules(rules) do
    Enum.reduce(rules, %{}, fn {left, right}, acc ->
      acc
      |> Map.put_new_lazy(left, fn -> {comes_before(left, rules), comes_after(left, rules)} end)
      |> Map.put_new_lazy(right, fn -> {comes_before(right, rules), comes_after(right, rules)} end)
    end)
  end

  # May want to raise if we see dupes here.
  defp numbers_before(number, numbers) do
    {_, before, afterr} =
      Enum.reduce(numbers, {false, [], []}, fn n, {spotted?, before, afterr} ->
        if spotted? do
          {spotted?, before, [n | afterr]}
        else
          if n == number do
            {true, before, afterr}
          else
            {false, [n | before], afterr}
          end
        end
      end)

    {before, afterr}
  end

  @pipe "|"
  def rules_reports(<<@new_line, @new_line, rest::binary>>, rules) do
    {Enum.reverse(rules), parse_reports(rest, [], [])}
  end

  def rules_reports(<<@new_line, rest::binary>>, acc), do: rules_reports(rest, acc)

  def rules_reports(<<left::binary-size(2), @pipe, right::binary-size(2), rest::binary>>, rules) do
    rules_reports(rest, [{String.to_integer(left), String.to_integer(right)} | rules])
  end

  def parse_reports(<<>>, _report, reports), do: Enum.reverse(reports)

  def parse_reports(<<@new_line, rest::binary>>, report, reports) do
    parse_reports(rest, [], [Enum.reverse(report) | reports])
  end

  def parse_reports(<<@comma, rest::binary>>, report, reports) do
    parse_reports(rest, report, reports)
  end

  def parse_reports(<<numb::binary-size(2), rest::binary>>, report, reports) do
    parse_reports(rest, [String.to_integer(numb) | report], reports)
  end

  # defp test_input_5() do
  #   """
  #   47|53
  #   97|13
  #   97|61
  #   97|47
  #   75|29
  #   61|13
  #   75|53
  #   29|13
  #   97|29
  #   53|29
  #   61|53
  #   97|53
  #   61|29
  #   47|13
  #   75|47
  #   97|75
  #   47|61
  #   75|61
  #   47|29
  #   75|13
  #   53|13

  #   75,47,61,53,29
  #   97,61,53,29,13
  #   75,29,13
  #   75,97,47,61,53
  #   61,13,29
  #   97,13,75,29,47
  #   """
  # end

  @doc """
  Basically fix the ones from part 1 that were ber-oken.
  """
  def day_5_2() do
    input = File.read!("./day_5_input.txt")
    {rules, reports} = rules_reports(input, [])

    rules = numbers_in_rules(rules)

    Enum.reduce(reports, 0, fn report, mid_number_sum ->
      report_good? =
        Enum.all?(report, fn number ->
          {must_come_before, must_come_after} = Map.fetch!(rules, number)
          {comes_after, comes_before} = numbers_before(number, report)

          (comes_after == [] || not Enum.any?(comes_after, &(&1 in must_come_before))) &&
            (comes_before == [] || not Enum.all?(comes_before, &(&1 in must_come_after)))
        end)

      if report_good? do
        mid_number_sum
      else
        # Kinda nasty to do this after? As could do it in the moment. but yea
        mid = Enum.at(fix_report(report, rules), div(length(report), 2))
        mid_number_sum + mid
      end
    end)
  end

  def is_less_than?(number, another, rules) do
    {_must_come_before, must_come_after} = Map.fetch!(rules, number)
    another in must_come_after
  end

  # always an odd number of items in report as there is always a mid point.
  defp fix_report(report, rules) do
    Enum.sort_by(report, & &1, fn left, right -> !is_less_than?(left, right, rules) end)
  end

  @doc """
  Example grid

    # grid = "
    # ....#.....
    # .........#
    # ..........
    # ..#.......
    # .......#..
    # ....012345
    # .#..^.....
    # ........#.
    # #.........
    # ......#...
    # "

  like route finding. Find all unique steps though. Feels like indexing into a binary might
  be fastest. But to do that will need primitives like:

    - Find up until object (or exit)
    - Find down until object (or exit)
    - Find left until object (or exit)
    - Find right until object (or exit)

  All these just become keeping pointers into the original binary and adding / subtracting
  from them as needed.

  First, find index of caret. That's easy.
  Next keep track of direction in some way.
    NB may have to turn multiple times.

  Keep track of visited paths? knowing how to deduplicate is key. Maybe just uniquely index
  them with x/y and then Enum.uniq the elements at the end.

  4939 was the answer

  Comapred using map for visited nodes:

    Name                   ips        average  deviation         median         99th %
    Day 6 1 LIST        727.09        1.38 ms     ±7.15%        1.35 ms        1.68 ms
    Day 6 1 MAP         663.04        1.51 ms     ±7.25%        1.49 ms        1.83 ms

    Comparison:
    Day 6 1 LIST        727.09
    Day 6 1 MAP         663.04 - 1.10x slower +0.133 ms

    Memory usage statistics:

    Name                 average  deviation         median         99th %
    Day 6 1 LIST         2.83 MB     ±0.00%        2.83 MB        2.83 MB
    Day 6 1 MAP          2.78 MB     ±0.00%        2.78 MB        2.78 MB

    Comparison:
    Day 6 1 LIST         2.83 MB
    Day 6 1 MAP          2.78 MB - 0.98x memory usage -0.05599 MB

    Reduction count statistics:

    Name         Reduction count
    Day 6 1 LIST         74.29 K
    Day 6 1 MAP          65.84 K - 0.89x reduction count -8.44900 K

    **All measurements for reduction count were the same**
  """
  def day_6_1() do
    grid = File.read!("./day_6_input.txt")
    max_width = map_width(grid, 0)
    {x, y} = find_start(grid, {0, 0})
    walk(grid, :up, {x, y}, max_width, [{x, y}])
  end

  def map_width(<<@new_line, _::binary>>, count), do: count + 1
  def map_width(<<_::binary-size(1), rest::binary>>, count), do: map_width(rest, count + 1)

  @block "#"
  defp walk(grid, direction, coords, max_width, visited) do
    new_coords = coord_for_direction(direction, coords)

    case move(grid, new_coords, max_width) do
      :exited_map -> length(Enum.uniq(visited))
      :block -> walk(grid, turn_right(direction), coords, max_width, visited)
      :cont -> walk(grid, direction, new_coords, max_width, [new_coords | visited])
    end
  end

  # This approach is a little faster if you use map_size rather than length(Map.keys)
  def day_6_1_map() do
    grid = File.read!("./day_6_input.txt")
    max_width = map_width(grid, 0)
    {x, y} = find_start(grid, {0, 0})
    walk_map(grid, :up, {x, y}, max_width, %{{x, y} => 1})
  end

  defp walk_map(grid, direction, coords, max_width, visited) do
    new_coords = coord_for_direction(direction, coords)

    case move(grid, new_coords, max_width) do
      :exited_map ->
        map_size(visited)

      :block ->
        walk_map(grid, turn_right(direction), coords, max_width, visited)

      :cont ->
        walk_map(grid, direction, new_coords, max_width, Map.put_new(visited, new_coords, 1))
    end
  end

  defp coord_for_direction(:up, {x, y}), do: {x, y - 1}
  defp coord_for_direction(:down, {x, y}), do: {x, y + 1}
  defp coord_for_direction(:left, {x, y}), do: {x - 1, y}
  defp coord_for_direction(:right, {x, y}), do: {x + 1, y}

  defp move(grid, {x, y}, max) do
    # The grid is square so these are the same (the input file gets saved with a new line at the end)
    if x < 0 || y < 0 || x > max - 2 || y > max - 2 do
      :exited_map
    else
      <<_::binary-size(x + max * y), rest::binary>> = grid

      case rest do
        <<@block, _::binary>> -> :block
        _ -> :cont
      end
    end
  end

  defp turn_right(:up), do: :right
  defp turn_right(:down), do: :left
  defp turn_right(:left), do: :up
  defp turn_right(:right), do: :down

  @caret "^"
  def find_start(<<@caret, _::binary>>, {x, y}), do: {x, y}
  def find_start(<<@new_line, rest::binary>>, {_, y}), do: find_start(rest, {0, y + 1})
  def find_start(<<_::binary-size(1), rest::binary>>, {x, y}), do: find_start(rest, {x + 1, y})
end
