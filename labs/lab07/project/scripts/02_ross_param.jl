## Параметрическое исследование модели Росса
# ### Активация проекта
using DrWatson
@quickactivate "project"
using ResumableFunctions, ConcurrentSim, Distributions, StableRNGs
using DataFrames, Plots, Statistics, CSV

script_name = splitext(basename(PROGRAM_FILE))[1]
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

const LAMBDA = 100.0
const MU = 1.0

@resumable function machine(env::Environment, repair_facility::Resource, spares::Store{Process}, rng, F, G, mon)
    while true
        try
            @yield timeout(env, Inf)
        catch
        end
        @yield timeout(env, rand(rng, F))
        mon[:functional] -= 1
        push!(mon[:log], (time=now(env), count=mon[:functional]))
        get_spare = take!(spares)
        @yield get_spare | timeout(env)
        if state(get_spare) != ConcurrentSim.idle
            @yield interrupt(value(get_spare))
        else
            throw(StopSimulation("No more spares!"))
        end
        t_req = now(env)
        @yield request(repair_facility)
        push!(mon[:waits], now(env) - t_req)
        d = rand(rng, G)
        @yield timeout(env, d)
        push!(mon[:repair_time], d)
        @yield unlock(repair_facility)
        mon[:functional] += 1
        push!(mon[:log], (time=now(env), count=mon[:functional]))
        @yield put!(spares, active_process(env))
    end
end

@resumable function start_sim(env::Environment, repair_facility::Resource, spares::Store{Process}, rng, F, G, mon, N, S)
    for i in 1:N
        proc = @process machine(env, repair_facility, spares, rng, F, G, mon)
        @yield interrupt(proc)
    end
    for i in 1:S
        proc = @process machine(env, repair_facility, spares, rng, F, G, mon)
        @yield put!(spares, proc)
    end
end

function sim_repair(N, S, num_repairmen, seed)
    rng = StableRNG(seed)
    F = Exponential(LAMBDA)
    G = Exponential(MU)
    mon = Dict(:functional => N + S, :log => NamedTuple[],
               :waits => Float64[], :repair_time => Float64[])
    sim = Simulation()
    repair_facility = Resource(sim, num_repairmen)
    spares = Store{Process}(sim)
    @process start_sim(sim, repair_facility, spares, rng, F, G, mon, N, S)
    msg = run(sim)
    return now(sim), mon
end

## Параметры эксперимента
param_dict = Dict(
    :N => [10, 12],
    :S => [2, 3],
    :repairmen => [1, 2],
)

## Создаём список всех комбинаций
params_list = dict_list(param_dict)
println("Всего комбинаций: $(length(params_list))")

rows = NamedTuple[]
for (i, p) in enumerate(params_list)
    println("Обработка $i/$(length(params_list))...")
    times_run = Float64[]
    for seed in [42, 43, 44]
        stop_time, mon = sim_repair(p[:N], p[:S], p[:repairmen], seed)
        push!(times_run, stop_time)
    end
    push!(rows, (N=p[:N], S=p[:S], repairmen=p[:repairmen], mean_crash=mean(times_run)))
end

df = DataFrame(rows)
CSV.write(datadir(script_name, "ross_param.csv"), df)

## График среднего времени падения
p = plot(1:nrow(df), df.mean_crash, seriestype=:bar,
         xticks=(1:nrow(df), ["N=$(r.N),S=$(r.S),R=$(r.repairmen)" for r in eachrow(df)]),
         ylabel="Среднее время падения", xlabel="Комбинация",
         legend=false, rotation=45)
savefig(p, plotsdir(script_name, "ross_param.png"))

println("✅ Результаты сохранены")
