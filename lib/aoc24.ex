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
end
