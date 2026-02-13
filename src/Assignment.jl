module Assignment

using Random

# problem representation
struct SetPartitioningProblem
    name::AbstractString
    rows::Int
    columns::Int
    """
    Can be thought of as the salaries of each air crew employee.
    The sum of a subset of these is what we have to minimise.
    """
    costs::Vector{Int}
    """
    Each crew member is a single column, and the rows are all the flight-legs we have to cover.
    The sum of every row given a selection of columns should be 1.
    OR equivalently, the sum of the entire matrix, given a selection of columns, should equal the number of rows.
    """
    partitions::Matrix{Int}
end

"""
Will read in any one of the 3 data files,
outputting a MxN matrix where M is the number of rows and N the number of columns.

Each file represents one instance of the set partitioning problem.
These files are from the OR-Library.

File structure explained: https://people.brunel.ac.uk/~mastjjb/jeb/orlib/sppinfo.html
"""
function read_data_file(filepath::String)::SetPartitioningProblem
    contents = read(filepath, String)
    lines = split(contents, "\n"; keepempty=false)
    rows, columns = split(lines[1], " ")
    rows = parse(Int, rows)
    columns = parse(Int, columns)

    matrix = zeros(Int, rows, columns)
    costs = zeros(Int, columns)
    for (column_index, line) in enumerate(lines[2:end])
        values = parse.(Int, split(line, " "))
        cost = values[1]
        number_rows_covered = values[2]
        row_indices = values[3:end]

        costs[column_index] = cost
        for row_index in row_indices
            matrix[row_index, column_index] = 1
        end

        # checking the column sum is equal to the number of rows it covers
        @assert sum(matrix[:, column_index]) == number_rows_covered
    end
    return SetPartitioningProblem(filepath, rows, columns, costs, matrix)
end

# solution representation
struct Solution
    problem::SetPartitioningProblem
    column_indices::Vector{Int}
    total_cost::Int
end

Solution(problem::SetPartitioningProblem, column_indices::Vector{Int}) = Solution(
    problem,
    column_indices,
    sum(problem.costs[column_indices])
)

abstract type SolutionGenerationMechanism end
struct UniformlyRandom <: SolutionGenerationMechanism
    rng::AbstractRNG
end
UniformlyRandom() = UniformlyRandom(Random.default_rng())
struct AllColumns <: SolutionGenerationMechanism end
struct NoColumns <: SolutionGenerationMechanism end

generate_solution(problem::SetPartitioningProblem) = generate_solution(problem, UniformlyRandom())
generate_solution(problem::SetPartitioningProblem, mechanism::UniformlyRandom) = Solution(
    problem,
    randperm(mechanism.rng, problem.columns)[1:rand(mechanism.rng, 1:problem.columns)]
)
generate_solution(problem::SetPartitioningProblem, mechanism::AllColumns) = Solution(
    problem,
    collect(1:problem.columns)
)
generate_solution(problem::SetPartitioningProblem, mechanism::NoColumns) = Solution(
    problem,
    Int[]
)

feasible_rows(solution::Solution) =
    ones(Int, solution.problem.rows) - vec(sum(solution.problem.partitions[:, solution.column_indices]; dims=2))

is_feasible(solution::Solution) = feasible_rows(solution) == zeros(Int, solution.problem.rows)

# implementing simulated annealing
function sa_fitness(solution::Solution)
    return solution.total_cost
end

function generate_sa_neighbour(solution::Solution)::Solution
    return solution
end

function simulated_annealing(
    problem::SetPartitioningProblem;
    iterations::Int=1000,
    rng::Random.AbstractRNG=Random.default_rng(),
    verbose::Bool=true
)
    solution = generate_solution(problem, UniformlyRandom(rng))
    for iteration in 1:iterations
        if verbose
            println("$iteration: $(sa_fitness(solution))")
        end

        neighbour = generate_sa_neighbour(solution)

        if sa_fitness(solution) < sa_fitness(neighbour)
            solution = neighbour
        end
    end
    return solution
end

end
