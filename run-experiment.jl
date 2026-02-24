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
bga_rng = Random.Xoshiro(1234)
bga_config = Assignment.BGAConfig(;
    rng=bga_rng,
    v=1,
    epochs=1000,
    population=50,
    penalty=10000.0,
    selection=Assignment.BGASelectionConfig(;
        k=2
    ),
    reproduction=Assignment.BGACombinedReproduction()
)
bga_solution = Assignment.binary_genetic_algorithm(problem1; config=bga_config)