"""
A binary genotype that represents the solution as a bitstring, `genotype`.

The bitstring can be manipulated after encoding with `encode` (conceptually a constructor of this struct)
and a new solution returned back after decoding with `decode`.
"""
struct BinaryGenotypeSolution
    solution::Solution
    bitstring::BitVector
end

Base.show(io::IO, genotype::BinaryGenotypeSolution) = print(io, map(x -> x ? "1" : "0", genotype.bitstring) |> join)

function encode(solution::Solution)::BinaryGenotypeSolution
    zeroArray = zeros(Int, solution.problem.columns)

    for column in solution.columns
        zeroArray[column] = 1
    end

    return BinaryGenotypeSolution(
        solution,
        BitVector(zeroArray)
    )
end

function decode_bitstring_into_columns(bitstring::BitVector)
    return map(bit -> bit[2] ? bit[1] : 0, collect(enumerate(bitstring))) |> filter(x -> x > 0)
end

decode(genotype::BinaryGenotypeSolution)::Solution = Solution(
    genotype.solution.problem,
    decode_bitstring_into_columns(genotype.bitstring)
)

# a useful constructor for a new solution, given just the bitstring
function BinaryGenotypeSolution(problem::SetPartitioningProblem, bitstring::BitVector)
    return BinaryGenotypeSolution(Solution(problem, decode_bitstring_into_columns(bitstring)), bitstring)
end