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