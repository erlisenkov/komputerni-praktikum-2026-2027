using DrWatson
@quickactivate "project"
using StableRNGs, Distributions, ConcurrentSim, ResumableFunctions
using DataFrames, Plots, Statistics

# Параметры системы M/M/c
num_customers = 100
num_servers = 2
mu = 0.5
lam = 0.9
rho = lam / (num_servers * mu)

rng = StableRNG(123)
arrival_dist = Exponential(1 / lam)
service_dist = Exponential(1 / mu)

log = NamedTuple[]

@resumable function customer(env::Environment, server::Resource, id::Integer, t_a::Float64, d_s::Distribution)
    @yield timeout(env, t_a)
    push!(log, (time=now(env), type=:arrive, id=id))
    @yield request(server)
    push!(log, (time=now(env), type=:service_start, id=id))
    @yield timeout(env, rand(rng, d_s))
    @yield unlock(server)
    push!(log, (time=now(env), type=:service_end, id=id))
end

sim = Simulation()
server = Resource(sim, num_servers)

# ИСПРАВЛЕНО: времена прибытия через cumsum (без присваивания в цикле)
arrival_times = cumsum(rand(rng, arrival_dist, num_customers))
for i in 1:num_customers
    @process customer(sim, server, i, arrival_times[i], service_dist)
end
run(sim)

df = DataFrame(log)

# ИСПРАВЛЕНО: подсчёт внутри функции (избегаем soft-scope ошибки)
function compute_counts(df)
    times = Float64[]
    counts = Int[]
    cur = 0
    for row in eachrow(df)
        if row.type == :arrive
            cur += 1
        elseif row.type == :service_end
            cur -= 1
        end
        push!(times, row.time)
        push!(counts, cur)
    end
    return times, counts
end

times, counts = compute_counts(df)

arrive_t = Dict{Int, Float64}()
start_t = Dict{Int, Float64}()
for row in eachrow(df)
    if row.type == :arrive
        arrive_t[row.id] = row.time
    elseif row.type == :service_start
        start_t[row.id] = row.time
    end
end
waits = [start_t[i] - arrive_t[i] for i in 1:num_customers]

println("=== Результаты моделирования M/M/c ===")
println("Среднее время ожидания: ", round(mean(waits), digits=3))
println("Максимальное время ожидания: ", round(maximum(waits), digits=3))
println("Загрузка системы rho = ", rho)

# Аналитика (формулы Эрланга)
if rho < 1
    sum1 = sum((num_servers * rho)^k / factorial(k) for k in 0:(num_servers-1))
    sum2 = (num_servers * rho)^num_servers / (factorial(num_servers) * (1 - rho))
    P0 = 1 / (sum1 + sum2)
    Pwait = sum2 * P0
    Lq = rho / (1 - rho) * Pwait
    Wq = Lq / lam
    println("=== Аналитика (Эрланг) ===")
    println("P0 = ", round(P0, digits=3))
    println("Pwait = ", round(Pwait, digits=3))
    println("Lq = ", round(Lq, digits=3))
    println("Wq аналитическое = ", round(Wq, digits=3))
end

p1 = plot(times, counts, seriestype=:step, fill=(0, 0.2),
          label="Заявок в системе", xlabel="Время", ylabel="Число заявок",
          title="M/M/c: число заявок во времени", legend=:topleft)
savefig(p1, plotsdir("mmc_system.png"))

p2 = histogram(waits, bins=15, label="Модель",
               xlabel="Время ожидания", ylabel="Число заявок",
               title="M/M/c: распределение ожидания", legend=:topright)
savefig(p2, plotsdir("mmc_waits.png"))

println("✅ Графики сохранены в plots/")
