using DrWatson
@quickactivate "project"

include(srcdir("SIRPetri.jl"))
using .SIRPetri
using DataFrames, CSV, Plots

# Параметры
β = 0.3
γ = 0.1
tmax = 100.0

# Создаём сеть и выполняем симуляцию
net, u0, _ = build_sir_network(β, γ)
df = simulate_deterministic(net, u0, (0.0, tmax), saveat=0.2, rates=[β, γ])

# Создаём анимацию
anim = @animate for row in eachrow(df)
    bar(
        ["S", "I", "R"],
        [row.S, row.I, row.R],
        legend=false,
        ylims=(0, 1000),
        xlabel="Состояние",
        ylabel="Количество",
        title="Время=$(round(row.time, digits=1))",
        color=[:blue :red :green],
    )
end

# Сохраняем GIF
gif(anim, plotsdir("sir_animation.gif"), fps=10)

println("✅ Анимация сохранена в plots/sir_animation.gif")
