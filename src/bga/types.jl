# initialisation
abstract type BGAInitialisationScheme end

struct BGAUniformlyRandomInitialisation <: BGAInitialisationScheme end
struct BGAPseudoRandomInitialisation <: BGAInitialisationScheme end

# selection
struct BGASelectionConfig
    k::Int
end
BGASelectionConfig(; k::Int=2) = BGASelectionConfig(k)

# reproduction
abstract type BGAReproductionScheme end

struct BGAGenerationalReproduction <: BGAReproductionScheme end
struct BGACombinedReproduction <: BGAReproductionScheme end
struct BGAStochasticRankingReproduction <: BGAReproductionScheme
    number_of_sweeps::Int
    fitness_probability::Float64
end
BGAStochasticRankingReproduction(; N::Int, P_f::Float64) = BGAStochasticRankingReproduction(N, P_f)

# config
struct BGAConfig
    rng::Random.AbstractRNG
    verbosity::Int

    epochs::Int
    population::Int
    offspring::Int
    penalty::Float64
    initialisation::BGAInitialisationScheme
    selection::BGASelectionConfig
    reproduction::BGAReproductionScheme
    heuristic_improvement::Bool
end
BGAConfig(;
    rng::Random.AbstractRNG=Random.default_rng(),
    v=1,
    epochs=10,
    mu=10,
    lambda=10,
    penalty=1000.0,
    initialisation::BGAInitialisationScheme=BGAUniformlyRandomInitialisation(),
    selection::BGASelectionConfig=BGASelectionConfig(),
    reproduction::BGAReproductionScheme,
    heuristic_improvement=false
) = BGAConfig(rng, v, epochs, mu, lambda, penalty, initialisation, selection, reproduction, heuristic_improvement)

# population
mutable struct BGAPopulation
    solutions::Vector{BinaryGenotypeSolution}
end
Base.:+(a::BGAPopulation, b::BGAPopulation) = BGAPopulation(vcat(a.solutions, b.solutions))
Base.show(io::IO, population::BGAPopulation) = print(
    io,
    join(
        [
            "[$i] $(population.solutions[i].fitness) ($(population.solutions[i].penalty)): \t$(population.solutions[i])"
            for i in 1:length(population.solutions)
        ],
        "\n"
    )
)
# simulation
mutable struct BGASimulation
    problem::SetPartitioningProblem
    config::BGAConfig
    population::Union{BGAPopulation,Nothing}
    offspring::Union{BGAPopulation,Nothing}
end

# initialisation
function bga_initial_population!(sim::BGASimulation, ::BGAUniformlyRandomInitialisation)
    sim.population = BGAPopulation(
        [generate_solution(sim.problem, UniformlyRandom(sim.config.rng)) |> encode for _ in 1:sim.config.population]
    )
end