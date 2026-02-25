# initialisation
abstract type BGAInitialisationScheme end

struct BGAUniformlyRandomInitialisation <: BGAInitialisationScheme end
struct BGAPseudoRandomInitialisation <: BGAPseudoRandomInitialisation end

# selection
struct BGASelectionConfig
    k::Int
end
BGASelectionConfig(; k::Int=2) = BGASelectionConfig(k)

# reproduction
abstract type BGAReproductionScheme end

struct BGAGenerationalReproduction <: BGAReproductionScheme end
struct BGACombinedReproduction <: BGAReproductionScheme end

# config
struct BGAConfig
    rng::Random.AbstractRNG
    verbosity::Int

    epochs::Int
    population::Int
    penalty::Float64
    selection::BGASelectionConfig
    reproduction::BGAReproductionScheme
end
BGAConfig(;
    rng::Random.AbstractRNG=Random.default_rng(),
    v::Int=1,
    epochs::Int=10,
    population::Int=10,
    penalty::Float64=1000.0,
    selection::BGASelectionConfig=BGASelectionConfig(),
    reproduction::BGAReproductionScheme
) = BGAConfig(rng, v, epochs, population, penalty, selection, reproduction)

# population
mutable struct BGAPopulation
    solutions::Vector{BinaryGenotypeSolution}
end
Base.:+(a::BGAPopulation, b::BGAPopulation) = BGAPopulation(vcat(a.solutions, b.solutions))
Base.show(io::IO, population::BGAPopulation) = print(
    io,
    join(
        [
            "[$i] $(population.solutions[i].fitness): \t$(population.solutions[i])"
            for i in 1:length(population.solutions)
        ],
        "\n"
    )
)

function bga_initial_population(problem::SetPartitioningProblem, config::BGAConfig)::BGAPopulation
    return BGAPopulation(
        [generate_solution(problem, UniformlyRandom(config.rng)) |> encode for _ in 1:config.population]
    )
end

# simulation
mutable struct BGASimulation
    problem::SetPartitioningProblem
    config::BGAConfig
    population::BGAPopulation
    offspring::Union{BGAPopulation,Nothing}
end