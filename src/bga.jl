include("bga/genotype.jl")
include("bga/reproduction.jl")
include("bga/selection.jl")
include("bga/config.jl")
include("bga/population.jl")
include("bga/simulation.jl")

function bga_reproduction!(sim::BGASimulation, ::BGAGenerationalReproduction)
    sim.population = sim.offspring
end

function bga_reproduction!(sim::BGASimulation, ::BGACombinedReproduction)
    @assert !isnothing(sim.offspring) "offspring must be defined for reproduction to occur"
    combined = sim.population + sim.offspring
    sort!(combined.solutions; by=x -> x.fitness)
    combined.solutions = combined.solutions[1:sim.config.population]

    sim.population = combined
end

bga_reproduction!(sim::BGASimulation) = bga_reproduction!(sim, sim.config.reproduction)


function bga_fitness!(sim::BGASimulation)
    for solution in sim.population.solutions
        solution.fitness = sa_fitness(solution.solution; penalty=sim.config.penalty)
    end

    isnothing(sim.offspring) && return
    for solution in sim.offspring.solutions
        solution.fitness = sa_fitness(solution.solution; penalty=sim.config.penalty)
    end
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
        P1 = sort!(indices; by=index -> sim.population.solutions[index].fitness)[1]

        indices = filter!(i -> i != P1, randperm(rng, population_size))[1:k]
        P2 = sort!(indices; by=index -> sim.population.solutions[index].fitness)[1]
        parents[pair_index] = (P1, P2)
    end

    return parents
end

"""
Creates a new (conceptually and in memory) population of children from the parent indices.
Uniform crossover implementation.
"""
function bga_crossover!(parents::Vector{Tuple{Int,Int}}, sim::BGASimulation)
    new_solutions::Vector{BinaryGenotypeSolution} = []

    for parent_pair in parents
        inheritance_mask = BitVector(map(round, rand(sim.config.rng, sim.problem.columns)))
        parent1 = sim.population.solutions[parent_pair[1]].bitstring
        parent2 = sim.population.solutions[parent_pair[2]].bitstring
        child = (parent1 .& inheritance_mask) .| (parent2 .& .!inheritance_mask)
        push!(new_solutions, BinaryGenotypeSolution(sim.problem, child))
    end

    sim.offspring = BGAPopulation(new_solutions)
end

function bga_mutation!(genotype::BinaryGenotypeSolution, sim::BGASimulation)
    mutation_rate = 1 / sim.problem.columns
    genotype.bitstring .⊻= rand(sim.config.rng, sim.problem.columns) .<= mutation_rate
end

function bga_mutation!(sim::BGASimulation)
    @assert !isnothing(sim.offspring) "sim.offspring does not exist"

    for genotype in sim.offspring.solutions
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

    sim = BGASimulation(problem, config, population, nothing)
    bga_fitness!(sim)

    for epoch in 1:sim.config.epochs
        sim.config.verbosity >= 2 && println("Epoch-$epoch\tPopulation\n$(population)")

        parents = bga_selection(sim)

        # variation operators
        bga_crossover!(parents, sim)
        bga_mutation!(sim)

        # reproduction
        bga_fitness!(sim)
        bga_reproduction!(sim)

        sim.offspring = nothing
    end

    config.verbosity >= 1 && println("Final\tPopulation\n$(sim.population)")
    solutions = sort!([decode(genotype) for genotype in sim.population.solutions]; by=sol -> sol.total_cost)
    println(solutions)
end