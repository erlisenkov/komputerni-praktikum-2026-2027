## Моделирование эпидемии SIR с помощью сетей Петри
# ### Активация проекта и загрузка пакетов
using DrWatson
@quickactivate "project"
using Random

include(srcdir("SIRPetri.jl"))
using .SIRPetri
using DataFrames, CSV, Plots

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

## Параметры эксперимента
β = 0.3
γ = 0.1
tmax = 100.0

# Создаём сеть
net, u0, states = build_sir_network(β, γ)

## Детерминированная симуляция
df_det = simulate_deterministic(net, u0, (0.0, tmax), saveat=0.5, rates=[β, γ])
CSV.write(datadir(script_name, "sir_det.csv"), df_det)

## Стохастическая симуляция
Random.seed!(123)
df_stoch = simulate_stochastic(net, u0, (0.0, tmax), rates=[β, γ])
CSV.write(datadir(script_name, "sir_stoch.csv"), df_stoch)

## Визуализация
p_det = plot_sir(df_det)
savefig(plotsdir(script_name, "sir_det_dynamics.png"))

p_stoch = plot_sir(df_stoch)
savefig(plotsdir(script_name, "sir_stoch_dynamics.png"))

println("✅ Графики и данные сохранены")
