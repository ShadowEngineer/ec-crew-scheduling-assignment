

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

function Base.show(io::IO, problem::SetPartitioningProblem)
    matrix = join([join(problem.partitions[i, :]) for i in 1:problem.rows], "\n")
    print(io, "$(problem.rows)x$(problem.columns) SetPartitioningProblem($(problem.name))\n$(matrix)")
end