"""
A single solution to a given problem, represented as the choice of columns of the problem, with their precomputed cost.

The column indices array is always sorted to make working with it easier.
"""
struct Solution
    problem::SetPartitioningProblem
    column_indices::Vector{Int}
    total_cost::Int
    row_feasibility::Vector{Int}
    feasible::Bool
end


function Solution(problem::SetPartitioningProblem, column_indices::Vector{Int})
    feasible_rows = vec(sum(problem.partitions[:, column_indices]; dims=2)) - ones(Int, problem.rows)
    return Solution(
        problem,
        column_indices,
        sum(problem.costs[column_indices]),
        feasible_rows,
        feasible_rows == zeros(Int, problem.rows),
    )
end

abstract type SolutionGenerationMechanism end
struct UniformlyRandom <: SolutionGenerationMechanism
    rng::AbstractRNG
end
struct AllColumns <: SolutionGenerationMechanism end
struct NoColumns <: SolutionGenerationMechanism end

UniformlyRandom() = UniformlyRandom(Random.default_rng())

generate_solution(problem::SetPartitioningProblem) = generate_solution(problem, UniformlyRandom())
generate_solution(problem::SetPartitioningProblem, ::AllColumns) = Solution(problem, collect(1:problem.columns))
generate_solution(problem::SetPartitioningProblem, ::NoColumns) = Solution(problem, Int[])
function generate_solution(problem::SetPartitioningProblem, mechanism::UniformlyRandom)
    rng = mechanism.rng
    cols = problem.columns
    return Solution(problem, sort(randperm(rng, cols)[1:rand(rng, 1:cols)]))
end