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

  Once you know the second number you now also know the Direction, which limits the possibilities
  even further from there. EG say it's 76, well then the next can only be:

    77, 78, 79

  A valid line describes a path through all possible values. I guess it's of infinite depth
  though in theory.

  %{
    75 => %{
      76 => %{ 77 => %{}, 78 => %{}, 79 => %{}},
      77 => %{ 78 => %{}, 79 => %{}, 80 => %{}},
      78 => %{ },
      74 => %{ },
      73 => %{ },
      72 => %{ },
    }
  }
  321 is the answer.
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
  """
  def day_2_2() do
    "./day_2_1_input.txt"
    |> File.read!()
    |> String.split(@new_line, trim: true)
    |> Enum.reduce({problems, 0}, fn line, {problems, count} ->
      [one, two | rest] = line |> String.split(" ")
      one = String.to_integer(one)
      two = String.to_integer(two)
      diff = abs(one - two)

      problems = if diff > 0 && diff < 4, do: 0, else: 1
      sum_safe_reports([two | rest], one < two, {  count})
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
end
