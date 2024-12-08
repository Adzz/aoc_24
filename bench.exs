Benchee.run(
  %{
    # "Day 5 1" => fn -> Aoc24.day_5_1() end,
    "Day 6 1 MAP" => fn -> Aoc24.day_6_1_map() end,
    "Day 6 1 LIST" => fn -> Aoc24.day_6_1() end
  },
  time: 10,
  memory_time: 2,
  reduction_time: 2
)
