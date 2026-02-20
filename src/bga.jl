struct BGASelectionConfig
    k::Int
end
BGASelectionConfig(; k::Int=2) = BGASelectionConfig(k)
struct BGAConfig
    rng::Random.AbstractRNG
    verbosity::Int

    epochs::Int
    population::Int
    penalty::Float64
    selection::BGASelectionConfig
end
BGAConfig(;
    rng::Random.AbstractRNG=Random.default_rng(),
    v::Int=1,
    epochs::Int=10,
    population::Int=10,
    penalty::Float64=1000.0,
    selection::BGASelectionConfig=BGASelectionConfig()
) = BGAConfig(rng, v, epochs, population, penalty, selection)

include("genotype.jl")

mutable struct BGAPopulation
    solutions::Vector{BinaryGenotypeSolution}
    fitness::Vector{Float64}
end
BGAPopulation(solutions::Vector{BinaryGenotypeSolution}) = BGAPopulation(solutions, zeros(length(solutions)))
Base.show(io::IO, population::BGAPopulation) = print(
    io,
    join(["[$i] $(population.fitness[i]): \t$(population.solutions[i])" for i in 1:length(population.solutions)], "\n")
)

function bga_initial_population(problem::SetPartitioningProblem, config::BGAConfig)::BGAPopulation
    return BGAPopulation(
        [generate_solution(problem, UniformlyRandom(config.rng)) |> encode for _ in 1:config.population]
    )
end

function bga_fitness(population::BGAPopulation, config::BGAConfig)
    return [sa_fitness(solution.solution; penalty=config.penalty) for solution in population.solutions]
end

"""
Returns a vector of tuples that contain the indices into the population for selection.
"""
function bga_select_parents(population::BGAPopulation, config::BGAConfig)::Vector{Tuple{Int,Int}}
    # deterministic binary tournament selection scheme implementation
    parents = Vector{Tuple{Int,Int}}(undef, config.population)
    for pair_index in 1:config.population
        indices = randperm(config.rng, config.population)[1:config.selection.k]
        P1 = sort!(indices; by=index -> population.fitness[index], rev=true)[1]

        indices = filter!(i -> i != P1, randperm(config.rng, config.population))[1:config.selection.k]
        P2 = sort!(indices; by=index -> population.fitness[index], rev=true)[1]
        parents[pair_index] = (P1, P2)
    end
    return parents
end

"""
Creates a new (conceptually and in memory) population of children from the parent indices.
Uniform crossover implementation.
"""
function bga_crossover(parents::Vector{Tuple{Int,Int}}, population::BGAPopulation, config::BGAConfig)::BGAPopulation
    new_solutions::Vector{} = []
    for parent_pair in parents
        # TODO make the number of columns easier to access
        # from some kind of "simulation snapshot" struct that combines config and problem
        gene_inheritance = rand(config.rng, length(population.solutions[1].bitstring))

    end
    return BGAPopulation(new_solutions)
end

function binary_genetic_algorithm(
    problem::SetPartitioningProblem;
    config::BGAConfig
)
    config.verbosity >= 2 && println("generating initial solutions...")
    population = bga_initial_population(problem, config)
    population.fitness = bga_fitness(population, config)

    for epoch in 1:config.epochs
        config.verbosity >= 2 && println("Epoch-$epoch\tPopulation\n$(population)")

        # selection
        parents = bga_select_parents(population, config)
        println(parents)

        # crossover to generate new children
        children = bga_crossover(parents, population, config)
        println(children)
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