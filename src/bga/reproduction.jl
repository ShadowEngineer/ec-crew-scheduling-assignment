abstract type BGAReproductionScheme end

struct BGAGenerationalReproduction <: BGAReproductionScheme end
struct BGASteadyStateReproduction <: BGAReproductionScheme
    replacement_portion::Float64
end
BGASteadyStateReproduction(; replacement_portion::Float64=0.3) = BGASteadyStateReproduction(replacement_portion)