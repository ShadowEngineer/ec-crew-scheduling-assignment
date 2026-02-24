mutable struct BGAPopulation
    solutions::Vector{BinaryGenotypeSolution}
end
Base.show(io::IO, population::BGAPopulation) = print(
    io,
    join(["[$i] $(population.solutions[i].fitness): \t$(population.solutions[i])"
          for i in 1:length(population.solutions)],
        "\n"
    )
)

function bga_initial_population(problem::SetPartitioningProblem, config::BGAConfig)::BGAPopulation
    return BGAPopulation(
        [generate_solution(problem, UniformlyRandom(config.rng)) |> encode for _ in 1:config.population]
    )
end

function Base.:+(a::BGAPopulation, b::BGAPopulation)
    return BGAPopulation(vcat(a.solutions, b.solutions))
end