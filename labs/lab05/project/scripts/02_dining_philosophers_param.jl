## Параметрическое исследование задачи "Обедающие философы"
# ### Активация проекта
using DrWatson
@quickactivate "project"

include(srcdir("DiningPhilosophers.jl"))
using .DiningPhilosophers
using DataFrames, CSV, Plots
using Random

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

## Параметры эксперимента
param_dict = Dict(
    :N => [3, 5],
    :tmax => [30.0, 50.0],
    :seed => [42, 123, 456],
)

## Создаём список всех комбинаций
params_list = dict_list(param_dict)

println("Всего комбинаций параметров: $(length(params_list))")

## Запуск экспериментов
for (i, params) in enumerate(params_list)
    println("Обработка $i/$(length(params_list))...")
    
    Random.seed!(params[:seed])
    
    net, u0, _ = build_classical_network(params[:N])
    df = simulate_stochastic(net, u0, params[:tmax])
    
    dead = detect_deadlock(df, net)
    
    plot_df = plot_marking_evolution(df, params[:N])
    plt_name = savename("dining", params) * ".png"
    
    # ИСПРАВЛЕНО: правильный порядок аргументов
    savefig(plot_df, plotsdir(plt_name))
    
    CSV.write(datadir(script_name, savename("dining", params) * ".csv"), df)
    
    println("  Deadlock: $dead")
end

println("\n✅ Все результаты сохранены")
