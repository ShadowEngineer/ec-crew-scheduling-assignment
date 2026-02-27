using Random
using Assignment
using JLD2
using ProgressMeter
using Base.Filesystem

RUN_SA = true
RUN_BGA = true
RUN_IBGA = true

problems = [
    Assignment.read_data_file("data/sppnw41.txt"),
    Assignment.read_data_file("data/sppnw42.txt"),
    Assignment.read_data_file("data/sppnw43.txt")
]

seeds = [Random.Xoshiro(10i) for i in 1:30]

total_problems = length(problems)
total_seeds = length(seeds)

function save_sols(solutions::Dict{String,Vector{Assignment.RunResult}}, algname::String)
    previous_files = filter(f -> isfile(f) && endswith(f, ".jld2") && contains(f, "-$algname-"), readdir(pwd()))
    filename = "solutions-$algname-latest.jld2"
    if length(previous_files) > 0
        next_file_number = maximum(map(s -> Int(split(s, "-")[3]), previous_files)) + 1
        rename(filename, "solutions-$algname-$(next_file_number).jld2")
    end

    println("Saving to: $filename")
    JLD2.save(filename, solutions)
end

# 
progress(desc::String) = Progress(total_seeds; dt=0.1, desc=desc, barglyphs=BarGlyphs(""))

# simulated annealing
start = time()
if RUN_SA
    println("Running simulated annealing...")
    solutions_sa = Dict([problem.name => Assignment.RunResult[] for problem in problems])

    for (pindex, problem) in enumerate(problems)
        prog = progress("  SA on $(problem.name)")
        for (sindex, seed) in enumerate(seeds)
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

            push!(solutions_sa[problem.name], result)
            next!(prog)
        end
    end

    save_sols(solutions_sa, "sa")
end

# binary genetic algorithm
μ = 50
λ = 2μ
epochs = 1000
penalty = 10000.0

if RUN_BGA
    solutions_bga = Dict([problem.name => Assignment.RunResult[] for problem in problems])

    for (pindex, problem) in enumerate(problems)
        prog = progress(" BGA on $(problem.name)")
        for (sindex, seed) in enumerate(seeds)
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

            push!(solutions_bga[problem.name], result)
            next!(prog)
        end
    end

    save_sols(solutions_bga, "bga")
end

# improved binary genetic algorithm
if RUN_IBGA
    solutions_ibga = Dict([problem.name => Assignment.RunResult[] for problem in problems])

    for (pindex, problem) in enumerate(problems)
        prog = progress("IBGA on $(problem.name)")
        for (sindex, seed) in enumerate(seeds)
            config = Assignment.BGAConfig(;
                rng=seed,
                v=0,
                epochs=epochs,
                mu=μ,
                lambda=λ,
                penalty=penalty,
                initialisation=Assignment.BGAPseudoRandomInitialisation(),
                selection=Assignment.BGASelectionConfig(; k=2),
                reproduction=Assignment.BGAStochasticRankingReproduction(; N=λ, P_f=0.5),
                heuristic_improvement=true,
            )
            result = Assignment.binary_genetic_algorithm(problem; config=config)

            push!(solutions_ibga[problem.name], result)
            next!(prog)
        end
    end

    save_sols(solutions_ibga, "ibga")
end
finish = time()

println("All simulations finished. Total time: $(finish - start)")