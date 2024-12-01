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
end
