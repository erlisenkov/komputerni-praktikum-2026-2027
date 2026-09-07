## Параметрическое исследование модели SIR
# ### Активация проекта
using DrWatson
@quickactivate "project"
include(srcdir("sir_model.jl"))
using Random, StatsPlots, DataFrames, CSV

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

## Параметры эксперимента
param_dict = Dict(
    :β => [0.03, 0.05, 0.07],
    :c => [5.0, 10.0, 15.0],
    :γ => [0.25],
)

## Создаём список всех комбинаций
params_list = dict_list(param_dict)
println("Всего комбинаций: $(length(params_list))")

results = []
for (i, params) in enumerate(params_list)
    println("Обработка $i/$(length(params_list))...")
    
    u0 = [990, 10, 0]
    p = [params[:β], params[:c], params[:γ]]
    tmax = 40.0
    
    Random.seed!(1234)
    m = MakeSIRModel(u0, p)
    activate(m)
    sir_run(m, tmax)
    data = out(m)
    
    peak_I = maximum(data.I)
    peak_time = data.t[data.I .== peak_I][1]
    
    push!(results, (β=params[:β], c=params[:c], γ=params[:γ], 
                    peak_I=peak_I, peak_time=peak_time))
    
    # Сохраняем данные
    filename = savename("sir", params) * ".csv"
    CSV.write(datadir(script_name, filename), data)
end

## Строим сравнительный график
df_results = DataFrame(results)
CSV.write(datadir(script_name, "sir_param_summary.csv"), df_results)

p = plot(title="Параметрическое исследование", xlab="Время", ylab="Инфицированные")
for row in eachrow(df_results)
    filename = savename("sir", Dict(:β=>row.β, :c=>row.c, :γ=>row.γ)) * ".csv"
    data = CSV.read(datadir(script_name, filename), DataFrame)
    plot!(data.t, data.I, label="β=$(row.β), c=$(row.c)", lw=2)
end
savefig(p, plotsdir(script_name, "sir_param.png"))

println("✅ Результаты сохранены")
