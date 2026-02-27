include("bga/genotype.jl")
include("bga/types.jl")
include("bga/improvements.jl")

function bga_reproduction!(sim::BGASimulation, ::BGAGenerationalReproduction)
    @assert sim.config.population == sim.config.offspring "cannot produce a new generation of different size"
    sim.population = sim.offspring
end

function bga_reproduction!(sim::BGASimulation, ::BGACombinedReproduction)
    combined = sim.population + sim.offspring
    sort!(combined.solutions; by=x -> x.fitness + x.penalty)
    combined.solutions = combined.solutions[1:sim.config.population]

    sim.population = combined
end


function bga_fitness!(sim::BGASimulation)
    for genotype in sim.population.solutions
        genotype.fitness = sa_fitness(genotype.solution)
        genotype.penalty = sa_penalty(genotype.solution; penalty=sim.config.penalty)
    end

    isnothing(sim.offspring) && return
    for genotype in sim.offspring.solutions
        genotype.fitness = sa_fitness(genotype.solution)
        genotype.penalty = sa_penalty(genotype.solution; penalty=sim.config.penalty)
    end
end

"""
Returns a vector of tuples that contain the indices into the population for selection.
"""
function bga_selection(sim::BGASimulation)::Vector{Tuple{Int,Int}}
    # deterministic binary tournament selection scheme implementation
    μ = sim.config.population
    λ = sim.config.offspring
    rng = sim.config.rng
    k = sim.config.selection.k

    parents = Vector{Tuple{Int,Int}}(undef, λ)
    solutions = sim.population.solutions

    for pair_index in 1:λ
        indices = randperm(rng, μ)[1:k]
        P1 = sort!(indices; by=i -> solutions[i].fitness + solutions[i].penalty)[1]

        indices = filter!(i -> i != P1, randperm(rng, μ))[1:k]
        P2 = sort!(indices; by=i -> solutions[i].fitness + solutions[i].penalty)[1]
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

    # have to update the solution in the genotype for fitness/penalty calculations to be correct
    genotype.solution = decode(genotype)
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
    config.verbosity >= 1 && println("Running for $(config.epochs) epochs...")

    sim = BGASimulation(problem, config, nothing, nothing)

    config.verbosity >= 1 && println("Generating initial solutions...")
    bga_initial_population!(sim, sim.config.initialisation)
    bga_fitness!(sim)

    config.verbosity >= 2 && println("Initial population\n$(sim.population)")

    highest_epoch = 0
    for epoch in 1:sim.config.epochs
        sim.config.verbosity >= 3 && println("Epoch-$epoch\tPopulation\n$(sim.population)")

        parents = bga_selection(sim)

        # variation operators
        bga_crossover!(parents, sim)
        bga_mutation!(sim)

        # heuristic improvement operator on the offspring, if enabled
        heuristic_improvement_operator!(sim)

        # reproduction
        @assert !isnothing(sim.offspring) "offspring must be defined for reproduction to occur"
        bga_fitness!(sim)
        bga_reproduction!(sim, sim.config.reproduction)

        sim.offspring = nothing
        highest_epoch += 1
    end

    config.verbosity >= 2 && println("Final population\n$(sim.population)")

    solutions = sort!([decode(genotype) for genotype in sim.population.solutions]; by=sol -> sol.total_cost)
    config.verbosity >= 1 && println("Final solutions:\n", solutions)

    feasible_solutions = filter(sol::Solution -> sol.feasible, solutions)
    isempty(feasible_solutions) && return RunResult(solutions[1], highest_epoch)
    return RunResult(feasible_solutions[1], highest_epoch)
end