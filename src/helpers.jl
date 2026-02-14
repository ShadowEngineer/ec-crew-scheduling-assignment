
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
    @assert length(array) > 0 "Array must have elements in it!"
    @assert issorted(array) "Array must be sorted!"
    @assert start_index >= 1 "Start index must be a non-negative, non-zero index!"
    @assert start_index <= length(array) "Start index must be inside the array!"

    start_value = array[start_index]
    lower = start_index - 1
    upper = start_index + 1
    searching_down = true
    searching_up = true

    array_max = array[end] # can assume this since the array is sorted
    can_insert_up = array_max < max

    while searching_down || searching_up
        if lower >= 1
            expected_lower_value = start_value - (start_index - lower)
            if array[lower] < expected_lower_value
                return (lower + 1, expected_lower_value)
            end
            lower -= 1
        else
            searching_down = false
        end

        if upper <= length(array) && upper <= max && array[upper] <= max
            expected_upper_value = start_value + (upper - start_index)
            if array[upper] > expected_upper_value
                return (upper, expected_upper_value)
            end
            upper += 1
        else
            # special cases
            if upper > length(array) && can_insert_up
                return (upper, array_max + 1)
            end
            searching_up = false
        end
    end

    error("Array is full. No free next index after limit of $max")
end