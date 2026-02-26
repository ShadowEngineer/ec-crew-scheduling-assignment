function bga_initial_population!(sim::BGASimulation, ::BGAPseudoRandomInitialisation)
    rng = sim.config.rng
    problem = sim.problem

    I = collect(1:sim.problem.rows)

    sim.population = BGAPopulation(
        map(1:sim.config.population) do x
            U = copy(I)
            S = Int[]

            while !isempty(U)
                i = U[rand(rng, 1:length(U))]
                j_possibilities = filter(col -> isempty(beta_j(problem, col) ∩ setdiff(I, U)), alpha_i(problem, i))

                if !isempty(j_possibilities)
                    j = rand(rng, j_possibilities)
                    push!(S, j)
                    setdiff!(U, beta_j(problem, j))
                else
                    setdiff!(U, i)
                end
            end

            return Solution(sim.problem, sort!(S)) |> encode
        end
    )
end

function bga_reproduction!(sim::BGASimulation, stochastic_ranking::BGAStochasticRankingReproduction)
    λ = sim.config.offspring
    μ = sim.config.population
    @assert λ >= μ "λ >= μ required for (μ,λ)-ES strategy"

    # stochastic ranking algorithm
    N = stochastic_ranking.number_of_sweeps
    P_f = stochastic_ranking.fitness_probability
    offspring = sim.offspring.solutions

    swap(i, j) = offspring[i], offspring[j] = offspring[j], offspring[i]

    for _ in 1:N
        swap_occurred = false

        for j in 1:λ-1
            u = rand(sim.config.rng)

            current::BinaryGenotypeSolution = offspring[j]
            next::BinaryGenotypeSolution = offspring[j+1]
            if (current.penalty == next.penalty == 0) || u < P_f
                if (current.fitness > next.fitness)
                    swap(j, j + 1)
                    swap_occurred = true
                end
            else
                if (current.penalty > next.penalty)
                    swap(j, j + 1)
                    swap_occurred = true
                end
            end
        end

        if !swap_occurred
            break
        end
    end

    # truncation selection to pick offspring, (μ,λ)
    sim.offspring.solutions = offspring[1:μ]
    sim.population = sim.offspring
end