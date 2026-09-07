## Модель Лотки-Вольтерры (Хищник-Жертва)
# ### Активация проекта и загрузка пакетов
using DrWatson
@quickactivate "project"

using DifferentialEquations
using Plots
using DataFrames
using JLD2

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

### Определение модели
# Классическая модель хищник-жертва:
# du1/dt = α*u1 - β*u1*u2 (жертвы)
# du2/dt = δ*u1*u2 - γ*u2 (хищники)
function lotka_volterra!(du, u, p, t)
    α, β, δ, γ = p
    du[1] = α * u[1] - β * u[1] * u[2]
    du[2] = δ * u[1] * u[2] - γ * u[2]
end

### Параметры и начальные условия
# α - скорость размножения жертв
# β - скорость поедания жертв хищниками
# δ - скорость размножения хищников
# γ - смертность хищников
u0_lv = [10.0, 5.0] # Начальные популяции: [жертвы, хищники]
p_lv = [1.5, 1.0, 1.0, 3.0] # Параметры [α, β, δ, γ]
tspan_lv = (0.0, 200.0) # Длительность симуляции
dt_lv = 0.01 # Шаг интегрирования

### Решение задачи
prob_lv = ODEProblem(lotka_volterra!, u0_lv, tspan_lv, p_lv)
sol_lv = solve(prob_lv, Tsit5(), dt=dt_lv, reltol=1e-8, abstol=1e-10, saveat=0.1)

### Подготовка данных
# Сохраняем результаты в таблицу DataFrame
df_lv = DataFrame()
df_lv[!, :t] = sol_lv.t
df_lv[!, :prey] = [u[1] for u in sol_lv.u] # Жертвы
df_lv[!, :predator] = [u[2] for u in sol_lv.u] # Хищники

println("Первые 5 строк данных:")
println(first(df_lv, 5))

### Визуализация
# График фазового портрета (Жертвы vs Хищники)
plot(df_lv.prey, df_lv.predator, 
     label="Фазовый портрет", 
     xlabel="Популяция жертв", 
     ylabel="Популяция хищников",
     title="Модель Лотки-Вольтерры",
     lw=2, legend=:topright)

savefig(plotsdir(script_name, "phase_portrait.png"))
println("График сохранен в: ", plotsdir(script_name, "phase_portrait.png"))

### Сохранение результатов
@save datadir(script_name, "lotka_volterra_results.jld2") df_lv sol_lv
println("Данные сохранены в: ", datadir(script_name, "lotka_volterra_results.jld2"))
