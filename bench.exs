Benchee.run(
  %{
    "Day 5 1" => fn -> Aoc24.day_5_1() end,
    "Day 5 2" => fn -> Aoc24.day_5_2() end,
  },
  time: 10,
  memory_time: 2,
  reduction_time: 2
)
