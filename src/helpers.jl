
"""
The `array` is an array of sorted (ascending) non-duplicate, non-contiguous positive integers.
This function finds the closest "free space" for the next index in the array from `start_index`, and returns it alongside the expected value at that index.

The `max` optional parameter will stop when the upper-bound search reaches that by index OR value.
If both bound searches complete, an error is thrown stating that the array is full.

# Example
- Given [1, 3, 4, 7] and the index 3
- The algorithm will check index 2 (3) and index 4 (7) - but always left first, then right
- Finds that the lower value is 1 less and the upper value is 3 more - an upper gap!
- Returns the tuple (4, 5), corresponding to (index, value) of the closest free space that you could insert to.
"""
function find_free_index(array::Vector{Int}, start_index::Int; max::Union{Int}=typemax(Int))::Tuple{Int,Int}
    array_length = length(array)
    @assert array_length > 0 "Array must have elements in it!"
    @assert array_length < max "Array is full. No free next index after limit of $max"
    @assert issorted(array) "Array must be sorted!"
    @assert start_index >= 1 "Start index must be a non-negative, non-zero index!"
    @assert start_index <= array_length "Start index must be inside the array!"

    start_value = array[start_index]
    lower = start_index - 1
    upper = start_index + 1

    array_max = array[end] # can assume this since the array is sorted
    can_insert_up = array_max < max

    # finding lower bound
    lower_option = (0, 0)
    while true
        if lower >= 0
            expected_lower_value = start_value - (start_index - lower)
            if lower == 0 || (lower >= 1 && array[lower] < expected_lower_value)
                lower_option = (lower + 1, expected_lower_value)
                break
            end
            lower -= 1
        else
            break
        end
    end

    upper_option = (array_length + 1, max)
    while true
        if upper <= array_length && upper <= max && array[upper] <= max
            expected_upper_value = start_value + (upper - start_index)
            if array[upper] > expected_upper_value
                upper_option = (upper, expected_upper_value)
                break
            end
            upper += 1
        else
            # special cases
            if upper > array_length && can_insert_up
                upper_option = (upper, array_max + 1)
            end
            break
        end
    end

    lower_is_valid = all(lower_option .> 0)
    upper_is_valid = can_insert_up || upper_option[2] < max
    if lower_is_valid && upper_is_valid
        lower_distance = start_index - lower
        upper_distance = upper - start_index
        if lower_distance <= upper_distance
            return lower_option
        else
            return upper_option
        end
    elseif lower_is_valid
        return lower_option
    else
        return upper_option
    end
end

# paper [1]'s notation at the bottom of p323
"""
all the column indices where there's a 1 in the given row
"""
alpha_i(problem::SetPartitioningProblem, row_index::Int) = findall(==(1), problem.partitions[row_index, :])

"""
all the row indices where there's a 1 in the given column
"""
beta_j(problem::SetPartitioningProblem, column_index::Int) = findall(==(1), problem.partitions[:, column_index])