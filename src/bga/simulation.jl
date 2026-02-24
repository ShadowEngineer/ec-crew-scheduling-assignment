mutable struct BGASimulation
    problem::SetPartitioningProblem
    config::BGAConfig
    population::BGAPopulation
    offspring::Union{BGAPopulation,Nothing}
end