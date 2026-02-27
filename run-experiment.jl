using Random
using Assignment

problems = [
    Assignment.read_data_file("data/sppnw41.txt"),
    Assignment.read_data_file("data/sppnw42.txt"),
    Assignment.read_data_file("data/sppnw43.txt")
]

seeds = [Random.Xoshiro(10i) for i in 1:30]

solutions = Dict([
    problem => Dict(
        :sa => Assignment.RunResult[],
        :bga => Assignment.RunResult[],
        :ibga => Assignment.RunResult[]
    ) for problem in problems
])

total_problems = length(problems)
total_seeds = length(seeds)

# simulated annealing
for (pindex, problem) in enumerate(problems)
    for (sindex, seed) in enumerate(seeds)
        println("[$pindex/$total_problems] [$sindex/$total_seeds] Running simulated annealing...")

        config = Assignment.SAConfig(;
            iterations=10000,
            penalty=5.0,
            temperature=Assignment.SATemperatureConfig(
                T0=100,
                alpha=0.99,
            ),
            bailout=Assignment.SABailoutConfig(
                enabled=true,
                max_attempts=10
            ),
            normalised=true
        )
        result = Assignment.simulated_annealing(problem;
            rng=seed,
            settings=config,
            verbosity=0
        )

        push!(solutions[problem][:sa], result)
    end
end

# binary genetic algorithm
μ = 50
λ = 2μ
epochs = 1000
penalty = 10000.0

for (pindex, problem) in enumerate(problems)
    for (sindex, seed) in enumerate(seeds)
        println("[$pindex/$total_problems] [$sindex/$total_seeds] Running binary genetic algorithm...")

        config = Assignment.BGAConfig(;
            rng=seed,
            v=0,
            epochs=epochs,
            mu=μ,
            lambda=λ,
            penalty=penalty,
            initialisation=Assignment.BGAUniformlyRandomInitialisation(),
            selection=Assignment.BGASelectionConfig(; k=2),
            reproduction=Assignment.BGACombinedReproduction()
        )
        result = Assignment.binary_genetic_algorithm(problem; config=config)

        push!(solutions[problem][:bga], result)
    end
end

# improved binary genetic algorithm
for (pindex, problem) in enumerate(problems)
    for (sindex, seed) in enumerate(seeds)
        println("[$pindex/$total_problems] [$sindex/$total_seeds] Running improved binary genetic algorithm...")

        config = Assignment.BGAConfig(;
            rng=seed,
            v=0,
            epochs=epochs,
            mu=μ,
            lambda=λ,
            penalty=penalty,
            initialisation=Assignment.BGAPseudoRandomInitialisation(),
            selection=Assignment.BGASelectionConfig(; k=2),
            reproduction=Assignment.BGAStochasticRankingReproduction(; N=lambda, P_f=0.5),
            heuristic_improvement=true,
        )
        result = Assignment.binary_genetic_algorithm(problem; config=config)

        push!(solutions[problem][:ibga], result)
    end
end