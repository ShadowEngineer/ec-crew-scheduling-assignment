"""
The pseudorandom initialisation method from Paper 1, page 341.
"""
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

"""
The stochastic ranking algorithm (assuming μ,λ evolutionary strategy) from Paper 2, page 286.
"""
function bga_reproduction!(sim::BGASimulation, stochastic_ranking::BGAStochasticRankingReproduction)
    λ = sim.config.offspring
    μ = sim.config.population
    @assert λ >= μ "λ >= μ required for (μ,λ)-ES"

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

"""
The heuristic improvement operator from Paper 1, page 331.
"""
function heuristic_improvement_operator(sim::BGASimulation, genotype::BinaryGenotypeSolution)::BinaryGenotypeSolution
    rng = sim.config.rng
    I = collect(1:sim.problem.rows)
    problem = sim.problem

    S = copy(genotype.solution.columns)
    w = [length(alpha_i(problem, i) ∩ S) for i in I]
    T = copy(S)

    # DROP procedure
    while !isempty(T)
        j = rand(rng, T)
        T = setdiff(T, j)
        β_j = beta_j(problem, j)
        if any(i -> w[i] >= 2, β_j)
            S = setdiff(S, j)
            for i in β_j
                w[i] -= 1
            end
        end
    end

    # ADD procedure
    U = [i for i in I if w[i] == 0]
    V = copy(U)
    while !isempty(V)
        i = rand(rng, V)
        V = setdiff(V, i)
        possible_j = [j for j in alpha_i(problem, i) if beta_j(problem, j) ⊆ U]

        if isempty(possible_j)
            continue
        end

        j = possible_j[findmin(j -> problem.costs[j] / length(beta_j(problem, j)), possible_j)[2]]
        β_j = beta_j(problem, j)

        S = union(S, j)
        for i in β_j
            w[i] += 1
        end
        U = setdiff(U, β_j)
        V = setdiff(V, β_j)
    end

    return Solution(problem, sort(S)) |> encode
end

function heuristic_improvement_operator!(sim::BGASimulation)
    !sim.config.heuristic_improvement && return
    @assert !isnothing(sim.offspring) "Simulation must have offspring to perform heuristic improvement on."

    for i in 1:sim.config.offspring
        sim.offspring.solutions[i] = heuristic_improvement_operator(sim, sim.offspring.solutions[i])
    end
end