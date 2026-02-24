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
        P1 = sort!(indices; by=index -> population.fitness[index])[1]

        indices = filter!(i -> i != P1, randperm(config.rng, config.population))[1:config.selection.k]
        P2 = sort!(indices; by=index -> population.fitness[index])[1]
        parents[pair_index] = (P1, P2)
    end
    return parents
end

"""
Creates a new (conceptually and in memory) population of children from the parent indices.
Uniform crossover implementation.
"""
function bga_crossover(parents::Vector{Tuple{Int,Int}}, population::BGAPopulation, config::BGAConfig)::BGAPopulation
    # TODO make the number of columns easier to access
    # from some kind of "simulation snapshot" struct that combines config and problem
    bitstring_length = length(population.solutions[1].bitstring)
    problem = population.solutions[1].solution.problem

    new_solutions::Vector{BinaryGenotypeSolution} = []
    for parent_pair in parents
        inheritance_mask = BitVector(map(round, rand(config.rng, bitstring_length)))
        parent1 = population.solutions[parent_pair[1]].bitstring
        parent2 = population.solutions[parent_pair[2]].bitstring
        child = (parent1 .& inheritance_mask) .| (parent2 .& .!inheritance_mask)
        push!(new_solutions, BinaryGenotypeSolution(problem, child))
    end

    return BGAPopulation(new_solutions)
end

function bga_mutation!(genotype::BinaryGenotypeSolution, config::BGAConfig)
    bitstring_length = length(genotype.bitstring)
    mutation_rate = 1 / bitstring_length
    genotype.bitstring .⊻= rand(config.rng, bitstring_length) .<= mutation_rate
end

function bga_mutation!(population::BGAPopulation, config::BGAConfig)
    for genotype in population.solutions
        bga_mutation!(genotype, config)
    end
end

function binary_genetic_algorithm(
    problem::SetPartitioningProblem;
    config::BGAConfig
)
    config.verbosity >= 1 && println("running for $(config.epochs) epochs...")
    config.verbosity >= 1 && println("generating initial solutions...")
    population = bga_initial_population(problem, config)
    population.fitness = bga_fitness(population, config)

    for epoch in 1:config.epochs
        config.verbosity >= 2 && println("Epoch-$epoch\tPopulation\n$(population)")

        # selection
        parents = bga_select_parents(population, config)

        # crossover to generate new children
        children = bga_crossover(parents, population, config)

        # mutation
        bga_mutation!(children, config)

        # reproduction
        population = children
        population.fitness = bga_fitness(population, config)
    end

    config.verbosity >= 1 && println("Final\tPopulation\n$(population)")
    solutions = sort!([decode(genotype) for genotype in population.solutions]; by=sol -> sol.total_cost)
    println(solutions)
end