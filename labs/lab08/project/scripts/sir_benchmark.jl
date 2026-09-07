using DrWatson
@quickactivate "project"
include(srcdir("sir_model.jl"))
using Random, BenchmarkTools

# Большая популяция для теста производительности
u0 = [9900, 100, 0]
p = [0.05, 10.0, 0.25]
tmax = 40.0

Random.seed!(1234)

println("Создание модели с $(sum(u0)) индивидами...")
des_model = MakeSIRModel(u0, p)
activate(des_model)

println("Запуск бенчмарка...")
result = @benchmark sir_run($des_model, $tmax)

println("\n=== Результаты бенчмарка ===")
println(result)

# Сохраняем результат
open(datadir("benchmark_result.txt"), "w") do f
    println(f, result)
end

println("\n✅ Результат сохранён в data/benchmark_result.txt")
