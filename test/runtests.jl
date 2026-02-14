using Test
using Assignment

@testset "Assignment" begin
    @testset "find_free_index" begin
        @testset "empty array" begin
            @test_throws Exception Assignment.find_free_index([], 1)
        end

        @testset "unsorted array" begin
            @test_throws AssertionError Assignment.find_free_index([2, 1], 1)
            @test_throws AssertionError Assignment.find_free_index(collect(10:1), 1)
        end

        @testset "successfully finds closest index" begin
            @test Assignment.find_free_index([1, 3, 4, 7], 1) == (2, 2)
            @test Assignment.find_free_index([1, 3, 4, 7], 2) == (2, 2)
            @test Assignment.find_free_index([1, 3, 4, 7], 3) == (4, 5)
            @test Assignment.find_free_index([1, 3, 4, 7], 4) == (4, 6)
        end

        @testset "breaks with out of bounds indices" begin
            @test_throws AssertionError Assignment.find_free_index([1, 3, 4, 7], 0)
            @test_throws AssertionError Assignment.find_free_index([1, 3, 4, 7], 5)
        end

        @testset "adheres to max bound by index and value" begin
            @test Assignment.find_free_index([2, 3, 4, 5], 4; max=5) == (1, 1)
            @test Assignment.find_free_index([1, 2, 3, 4], 1; max=5) == (5, 5)
        end

        @testset "full arrays" begin
            @test Assignment.find_free_index([1, 2, 3], 1) == (4, 4)
            @test_throws Exception Assignment.find_free_index([1, 2, 3], 1; max=3)
        end
    end
end