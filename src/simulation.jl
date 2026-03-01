using JLD2
using ProgressMeter
using Base.Filesystem

function save_solutions(solutions::Dict{String,Vector{RunResult}}, algname::String)
    previous_files = filter(f -> isfile(f) && endswith(f, ".jld2") && contains(f, "-$algname-"), readdir(pwd()))
    filename = "solutions-$algname-latest.jld2"
    if length(previous_files) > 0
        previous_files = filter(f -> !contains(f, "latest"), previous_files)
        if length(previous_files) == 0
            next_file_number = 1
        else
            next_file_number = maximum(map(s -> parse(Int, split(split(s, ".")[1], "-")[3]), previous_files)) + 1
        end
        rename(filename, "solutions-$algname-$(next_file_number).jld2")
    end

    println("Saving to: $filename")
    JLD2.save(filename, solutions)
end

function run_experiment(; run_sa=false, run_bga=false, run_ibga=false)

    problems = [
        read_data_file(pkgdir(Assignment, "data", "sppnw41.txt")),
        read_data_file(pkgdir(Assignment, "data", "sppnw42.txt")),
        read_data_file(pkgdir(Assignment, "data", "sppnw43.txt"))
    ]

    seeds = [Random.Xoshiro(10i) for i in 1:30]

    total_problems = length(problems)
    total_seeds = length(seeds)

    # 
    progress(desc::String) = Progress(total_seeds; dt=0.1, desc=desc, barglyphs=BarGlyphs(""))

    # simulated annealing
    start = time()
    if run_sa
        println("Running simulated annealing...")
        solutions_sa = Dict([problem.name => RunResult[] for problem in problems])

        for (pindex, problem) in enumerate(problems)
            prog = progress("  SA on $(problem.name)")
            for (sindex, seed) in enumerate(seeds)
                config = SAConfig(;
                    iterations=10000,
                    penalty=5.0,
                    temperature=SATemperatureConfig(
                        T0=100,
                        alpha=0.99,
                    ),
                    bailout=SABailoutConfig(
                        enabled=false,
                        max_attempts=10
                    ),
                    normalised=true
                )
                result = simulated_annealing(problem;
                    rng=seed,
                    settings=config,
                    verbosity=0
                )

                push!(solutions_sa[problem.name], result)
                next!(prog)
            end
        end

        save_solutions(solutions_sa, "sa")
    end

    # binary genetic algorithm
    μ = 100
    λ = 2μ
    epochs = 1000
    penalty = 10000.0

    if run_bga
        solutions_bga = Dict([problem.name => RunResult[] for problem in problems])

        for (pindex, problem) in enumerate(problems)
            prog = progress(" BGA on $(problem.name)")
            for (sindex, seed) in enumerate(seeds)
                config = BGAConfig(;
                    rng=seed,
                    v=0,
                    epochs=epochs,
                    mu=μ,
                    lambda=λ,
                    penalty=penalty,
                    initialisation=BGAUniformlyRandomInitialisation(),
                    selection=BGASelectionConfig(; k=2),
                    reproduction=BGACombinedReproduction()
                )
                result = binary_genetic_algorithm(problem; config=config)

                push!(solutions_bga[problem.name], result)
                next!(prog)
            end
        end

        save_solutions(solutions_bga, "bga")
    end

    # improved binary genetic algorithm
    if run_ibga
        solutions_ibga = Dict([problem.name => RunResult[] for problem in problems])

        for (pindex, problem) in enumerate(problems)
            prog = progress("IBGA on $(problem.name)")
            for (sindex, seed) in enumerate(seeds)
                config = BGAConfig(;
                    rng=seed,
                    v=0,
                    epochs=epochs,
                    mu=μ,
                    lambda=λ,
                    penalty=penalty,
                    initialisation=BGAPseudoRandomInitialisation(),
                    selection=BGASelectionConfig(; k=2),
                    reproduction=BGAStochasticRankingReproduction(; N=λ, P_f=0.5),
                    heuristic_improvement=true,
                )
                result = binary_genetic_algorithm(problem; config=config)

                push!(solutions_ibga[problem.name], result)
                next!(prog)
            end
        end

        save_solutions(solutions_ibga, "ibga")
    end
    finish = time()

    println("All simulations finished. Total time: $(finish - start)")
end