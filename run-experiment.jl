using Random
using Assignment

problem1 = Assignment.read_data_file("data/sppnw41.txt")

# simulated annealing
generator = Random.Xoshiro(1234)

sa_config = Assignment.SAAlgorithmConfig(;
    iterations=300,
    penalty=5.0,
    temperature=Assignment.SATemperatureConfig(
        T0=100,
        alpha=0.98,
    ),
    bailout=Assignment.SABailoutConfig(
        enabled=false,
        max_attempts=5
    ),
    normalised=true
)
sa_solution = Assignment.simulated_annealing(problem1; rng=generator, settings=sa_config)