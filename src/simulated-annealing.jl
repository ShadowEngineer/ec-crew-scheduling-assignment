struct SATemperatureConfig
    T0::Int
    alpha::Float64
end
SATemperatureConfig(; T0=100, alpha=0.98) = SATemperatureConfig(T0, alpha)

struct SABailoutConfig
    enabled::Bool
    max_attempts::Int
end
SABailoutConfig(; enabled=false, max_attempts=5) = SABailoutConfig(enabled, max_attempts)

struct SAConfig
    iterations::Int
    penalty::Float64
    temperature::SATemperatureConfig
    bailout::SABailoutConfig
    P::Union{Float64,Nothing}
    normalised::Bool
end
SAConfig(;
    iterations=300,
    penalty=1000.0,
    temperature=SATemperatureConfig(),
    bailout=SABailoutConfig(),
    P=nothing,
    normalised=true
) = SAConfig(iterations, penalty, temperature, bailout, P, normalised)


sa_penalty(solution::Solution; penalty=0.0) = sum(abs.(solution.row_feasibility)) * penalty
sa_fitness(solution::Solution; penalty=0.0, normalising_factor=1.0) =
    solution.total_cost / normalising_factor + sa_penalty(solution; penalty)
sa_temperature(config::SATemperatureConfig, iterations::Int) = config.T0 * config.alpha^iterations
sa_probability(settings::SAConfig, solution_fitness, neighbour_fitness, temperature) =
    isnothing(settings.P) ?
    exp((solution_fitness - neighbour_fitness) / temperature) :
    settings.P

"""
Generates a new "neighbouring" solution, by stochastically adding/removing a column.
- When adding a column, it will pick one of the existing indices and randomly add a column into the closest nearby space. Which direction closest (left or right), is also random.
- When removing a column, it randomly picks one of the columns to remove.

Returns a new solution copy, instead of mutating the old one.
"""
function sa_neighbour(solution::Solution, rng::Random.AbstractRNG)::Solution
    must_add = length(solution.columns) == 0
    must_remove = length(solution.columns) == solution.problem.columns
    should_add = rand(rng) >= 0.5

    new_indices = copy(solution.columns)
    if must_add || (!must_remove && should_add)
        # add a new column
        if must_add
            push!(new_indices, rand(rng, 1:solution.problem.columns))
        else
            random_index = rand(rng, 1:length(solution.columns))
            index, value = find_free_index(solution.columns, random_index; max=solution.problem.columns)
            insert!(new_indices, index, value)
        end
    else
        # removing a column
        random_index = rand(rng, 1:length(solution.columns))
        popat!(new_indices, random_index)
    end

    return Solution(solution.problem, new_indices)
end

function simulated_annealing(
    problem::SetPartitioningProblem;
    rng::Random.AbstractRNG=Random.default_rng(),
    verbosity::Int=1,
    settings::SAConfig
)
    verbosity >= 1 && println("Running simulated annealing with $settings")

    # normalising all the column costs by the average cost of each column
    normalising_factor = 1.0
    if settings.normalised
        normalising_factor = sum(problem.costs) / problem.columns
        verbosity >= 1 && println("Normalising factor: $normalising_factor")
    end

    solution = generate_solution(problem, UniformlyRandom(rng))
    worst_neighbour_attempts = 0

    for iteration in 1:settings.iterations
        neighbour = sa_neighbour(solution, rng)

        neighbour_fitness = sa_fitness(neighbour; penalty=settings.penalty, normalising_factor)
        solution_fitness = sa_fitness(solution; penalty=settings.penalty, normalising_factor)

        temperature = sa_temperature(settings.temperature, iteration)
        escape_probability = sa_probability(settings, solution_fitness, neighbour_fitness, temperature)

        verbosity >= 2 && println("$iteration: $solution_fitness ($(solution.total_cost), $(solution.feasible)) - $worst_neighbour_attempts - $neighbour_fitness - $temperature - $(neighbour_fitness >= solution_fitness ? escape_probability : "none") - $(solution.columns)")

        if neighbour_fitness < solution_fitness || rand(rng) <= escape_probability
            solution = neighbour
            worst_neighbour_attempts = 0
        else
            worst_neighbour_attempts += 1
        end

        if settings.bailout.enabled && worst_neighbour_attempts > settings.bailout.max_attempts
            verbosity >= 1 && println("Exceeded neighbour jump attempts $(settings.bailout.max_attempts), bailing")
            break
        end
    end

    return solution
end