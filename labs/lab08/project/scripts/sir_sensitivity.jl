using DrWatson
@quickactivate "project"
include(srcdir("sir_model.jl"))
using Random, StatsPlots, DataFrames, CSV

# Параметры
tmax = 40.0
u0 = [990, 10, 0]

# Варьируем β
betas = [0.03, 0.05, 0.07]
results = []

for β in betas
    p = [β, 10.0, 0.25]
    Random.seed!(1234)
    
    m = MakeSIRModel(u0, p)
    activate(m)
    sir_run(m, tmax)
    data = out(m)
    
    peak_I = maximum(data.I)
    peak_time = data.t[data.I .== peak_I][1]
    
    push!(results, (β=β, peak_I=peak_I, peak_time=peak_time))
    
    # Сохраняем данные
    filename = "sir_beta_$(β).csv"
    CSV.write(datadir(filename), data)
end

# Строим сравнительный график
p = plot(title="Чувствительность к β", xlab="Время", ylab="Инфицированные")
for β in betas
    data = CSV.read(datadir("sir_beta_$(β).csv"), DataFrame)
    plot!(data.t, data.I, label="β=$β", lw=2)
end
savefig(p, plotsdir("sir_sensitivity.png"))

println("✅ Результаты сохранены")
