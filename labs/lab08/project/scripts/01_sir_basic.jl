## Дискретно-событийная модель SIR
# ### Активация проекта и загрузка пакетов
using DrWatson
@quickactivate "project"
include(srcdir("sir_model.jl"))
using Random, StatsPlots

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

## Параметры модели
tmax = 40.0
u0 = [990, 10, 0] # S, I, R
p = [0.05, 10.0, 0.25] # β, c, γ

Random.seed!(1234)

## Запуск модели
des_model = MakeSIRModel(u0, p)
activate(des_model)
sir_run(des_model, tmax)
data_des = out(des_model)

## Визуализация
@df data_des plot(
    :t, [:S :I :R], 
    labels=["S" "I" "R"], 
    xlab="Время", 
    ylab="Численность", 
    title="Дискретно-событийная SIR модель",
    lw=2
)
savefig(plotsdir(script_name, "sir_des.png"))

println("✅ График сохранён")
