# Моделирование задачи "Обедающие философы"

using DrWatson
@quickactivate "project"

include(srcdir("DiningPhilosophers.jl"))
using .DiningPhilosophers
using DataFrames, CSV, Plots

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

# Параметры эксперимента
N = 5
tmax = 50.0

# Классическая сеть (без арбитра)
println("=== Классическая сеть (без арбитра) ===")
net_classic, u0_classic, _ = build_classical_network(N)

df_classic = simulate_stochastic(net_classic, u0_classic, tmax)
CSV.write(datadir(script_name, "dining_classic.csv"), df_classic)

dead = detect_deadlock(df_classic, net_classic)
println("Deadlock обнаружен: $dead")

plot_classic = plot_marking_evolution(df_classic, N)
savefig(plotsdir(script_name, "classic_simulation.png"))

# Сеть с арбитром
println("\n=== Сеть с арбитром ===")
net_arb, u0_arb, _ = build_arbiter_network(N)

df_arb = simulate_stochastic(net_arb, u0_arb, tmax)
CSV.write(datadir(script_name, "dining_arbiter.csv"), df_arb)

dead_arb = detect_deadlock(df_arb, net_arb)
println("Deadlock обнаружен: $dead_arb")

plot_arb = plot_marking_evolution(df_arb, N)
savefig(plotsdir(script_name, "arbiter_simulation.png"))

println("\n✅ Графики и данные сохранены")
