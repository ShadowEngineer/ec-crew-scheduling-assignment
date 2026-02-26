using Random
using Assignment

problem1 = Assignment.read_data_file("data/sppnw41.txt")

# simulated annealing
sa_generator = Random.Xoshiro(1234)

sa_config = Assignment.SAConfig(;
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
# sa_solution = Assignment.simulated_annealing(problem1; rng=sa_generator, settings=sa_config, verbosity=1)

# binary genetic algorithm
mu = 50
lambda = mu * 2
bga_rng = Random.Xoshiro(1234)
bga_config = Assignment.BGAConfig(;
    rng=bga_rng,
    v=1,
    epochs=1000,
    mu=mu,
    lambda=lambda,
    penalty=10000.0,
    initialisation=Assignment.BGAUniformlyRandomInitialisation(),
    selection=Assignment.BGASelectionConfig(;
        k=2
    ),
    reproduction=Assignment.BGACombinedReproduction()
)
# bga_sim = Assignment.binary_genetic_algorithm(problem1; config=bga_config)

# improved binary genetic algorithm
bga_improved_rng = Random.Xoshiro(1234)
bga_improved_config = Assignment.BGAConfig(;
    rng=bga_improved_rng,
    v=bga_config.verbosity,
    epochs=bga_config.epochs,
    mu=mu,
    lambda=lambda,
    penalty=bga_config.penalty,
    initialisation=Assignment.BGAPseudoRandomInitialisation(),
    selection=bga_config.selection,
    reproduction=Assignment.BGAStochasticRankingReproduction(;
        N=lambda,
        P_f=0.5
    )
)
bga_improved_sim = Assignment.binary_genetic_algorithm(problem1; config=bga_improved_config)

println("Finished!")