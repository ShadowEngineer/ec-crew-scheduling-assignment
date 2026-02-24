include("bga/genotype.jl")
include("bga/population.jl")
include("bga/reproduction.jl")
include("bga/selection.jl")
include("bga/config.jl")
include("bga/simulation.jl")

function bga_reproduction!(
    offspring::BGAPopulation,
    sim::BGASimulation,
    ::BGAGenerationalReproduction
)
    sim.population = offspring
end

function bga_reproduction!(
    offspring::BGAPopulation,
    sim::BGASimulation,
    steady_state::BGASteadyStateReproduction
)
    combined = parents + offspring
end

function bga_reproduction!(offspring::BGAPopulation, sim::BGASimulation)
    bga_reproduction!(offspring, sim, sim.config.reproduction)
end


function bga_fitness!(sim::BGASimulation)
    population = sim.population
    config = sim.config
    population.fitness = [sa_fitness(solution.solution; penalty=config.penalty) for solution in population.solutions]
end

"""
Returns a vector of tuples that contain the indices into the population for selection.
"""
function bga_selection(sim::BGASimulation)::Vector{Tuple{Int,Int}}
    # deterministic binary tournament selection scheme implementation
    population_size = sim.config.population
    rng = sim.config.rng
    k = sim.config.selection.k

    parents = Vector{Tuple{Int,Int}}(undef, population_size)

    for pair_index in 1:population_size
        indices = randperm(rng, population_size)[1:k]
        P1 = sort!(indices; by=index -> sim.population.fitness[index])[1]

        indices = filter!(i -> i != P1, randperm(rng, population_size))[1:k]
        P2 = sort!(indices; by=index -> sim.population.fitness[index])[1]
        parents[pair_index] = (P1, P2)
    end

    return parents
end

"""
Creates a new (conceptually and in memory) population of children from the parent indices.
Uniform crossover implementation.
"""
function bga_crossover(parents::Vector{Tuple{Int,Int}}, sim::BGASimulation)::BGAPopulation
    new_solutions::Vector{BinaryGenotypeSolution} = []

    for parent_pair in parents
        inheritance_mask = BitVector(map(round, rand(sim.config.rng, sim.problem.columns)))
        parent1 = sim.population.solutions[parent_pair[1]].bitstring
        parent2 = sim.population.solutions[parent_pair[2]].bitstring
        child = (parent1 .& inheritance_mask) .| (parent2 .& .!inheritance_mask)
        push!(new_solutions, BinaryGenotypeSolution(sim.problem, child))
    end

    return BGAPopulation(new_solutions)
end

function bga_mutation!(genotype::BinaryGenotypeSolution, sim::BGASimulation)
    mutation_rate = 1 / sim.problem.columns
    genotype.bitstring .⊻= rand(sim.config.rng, sim.problem.columns) .<= mutation_rate
end

function bga_mutation!(offspring::BGAPopulation, sim::BGASimulation)
    for genotype in offspring.solutions
        bga_mutation!(genotype, sim)
    end
end

function binary_genetic_algorithm(
    problem::SetPartitioningProblem;
    config::BGAConfig
)
    config.verbosity >= 1 && println("running for $(config.epochs) epochs...")
    config.verbosity >= 1 && println("generating initial solutions...")
    population = bga_initial_population(problem, config)

    sim = BGASimulation(problem, config, population)
    bga_fitness!(sim)

    for epoch in 1:sim.config.epochs
        sim.config.verbosity >= 2 && println("Epoch-$epoch\tPopulation\n$(population)")

        # selection
        parents = bga_selection(sim)

        # crossover to generate new children
        offspring = bga_crossover(parents, sim)

        # mutation
        bga_mutation!(offspring, sim)

        # reproduction
        bga_reproduction!(offspring, sim)
        bga_fitness!(sim)
    end

    config.verbosity >= 1 && println("Final\tPopulation\n$(sim.population)")
    solutions = sort!([decode(genotype) for genotype in sim.population.solutions]; by=sol -> sol.total_cost)
    println(solutions)
end