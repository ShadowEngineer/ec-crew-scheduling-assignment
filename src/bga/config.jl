struct BGAConfig
    rng::Random.AbstractRNG
    verbosity::Int

    epochs::Int
    population::Int
    penalty::Float64
    selection::BGASelectionConfig
    reproduction::BGAReproductionScheme
end
BGAConfig(;
    rng::Random.AbstractRNG=Random.default_rng(),
    v::Int=1,
    epochs::Int=10,
    population::Int=10,
    penalty::Float64=1000.0,
    selection::BGASelectionConfig=BGASelectionConfig(),
    reproduction::BGAReproductionScheme
) = BGAConfig(rng, v, epochs, population, penalty, selection, reproduction)