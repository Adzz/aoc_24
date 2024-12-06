Benchee.run(
  %{
    "part 1" => fn -> Aoc24.day4_1() end,
    "sevenseascat" => fn -> Y2024.Day04.part1() end,
    "Awlexus" => fn -> T.p1(File.read!("./day_4_input.txt")) end
  },
  time: 10,
  memory_time: 2,
  reduction_time: 2
)
