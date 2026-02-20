struct BGAConfig
    rng::Random.AbstractRNG
    verbosity::Int

    epochs::Int
    population::Int
    penalty::Float64
end
BGAConfig(;
    rng::Random.AbstractRNG=Random.default_rng(),
    v::Int=1,
    epochs::Int=10,
    P::Int=10,
    penalty::Float64=1000.0
) = BGAConfig(rng, v, epochs, P, penalty)

mutable struct BGAPopulation
    solutions::Vector{Solution}
    fitness::Vector{Float64}
end

function bga_initial_population(problem::SetPartitioningProblem, config::BGAConfig)::BGAPopulation
    return BGAPopulation(
        [generate_solution(problem, UniformlyRandom(config.rng)) for _ in 1:config.population],
        [0 for _ in 1:config.population]
    )
end

function bga_fitness(population::BGAPopulation, config::BGAConfig)
    return [sa_fitness(solution; penalty=config.penalty) for solution in population.solutions]
end

function binary_genetic_algorithm(
    problem::SetPartitioningProblem;
    config::BGAConfig
)
    config.verbosity >= 2 && println("generating initial solutions...")
    population = bga_initial_population(problem, config)
    population.fitness = bga_fitness(population, config)

    for epoch in 1:config.epochs
        config.verbosity >= 2 && println("$epoch: ")

        # perform selection
        # question: what exact selection scheme should be used for a standard BGA?
    end
end

#=
local epochs = {}
generations[0] = generate_initial_population()
local epoch = 0
local fitness = evaluate_fitness(generations[0])
while termination_flag == false
	-- selection phase
	local parents = select_best_parents(generations[epoch])
	-- variation phase
	local new_candidates = variation_operators(parents)
	-- fitness phase
	local new_fitness = evaluate_fitness(new_candidates)
	local fitness = table.join(fitness, new_fitness)
	-- reproduction phase
	generations[epoch + 1] = reproduce(
		table.join(generations[epoch], new_candidates),
		fitness
	)

	epoch = epoch + 1
	if should_terminate() then
		termination_flag = true
	end
end
print(find_best(epochs))
=#