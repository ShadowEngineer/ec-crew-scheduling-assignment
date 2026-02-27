### A Pluto.jl notebook ###
# v0.20.23

using Markdown
using InteractiveUtils

# ╔═╡ f8abd002-86af-485a-b10d-c4915cfdd8eb
begin
	import Pkg
	Pkg.activate(".")
end

# ╔═╡ af9d07b5-9c97-47cd-9563-60f89b3b8d6a
using DataFrames

# ╔═╡ abea3b54-bebb-4723-ac69-47b5023e4673
using Statistics, PrettyTables

# ╔═╡ 941e2f78-4b72-4c57-8c70-7b650e429cf3
import Assignment

# ╔═╡ 22b7ae42-13fe-11f1-8a6b-4b014f10eaba
import JLD2

# ╔═╡ e76196e4-d977-4c06-8b05-2f3c20c6397b
sa_solutions = JLD2.load("solutions-sa-latest.jld2")

# ╔═╡ cce8941a-f33c-410b-b6f4-13a5603f8de6
bga_solutions = JLD2.load("solutions-bga-latest.jld2")

# ╔═╡ c498c9f7-ad0f-48c7-bcbf-b6f0a2fd4185
ibga_solutions = JLD2.load("solutions-ibga-latest.jld2")

# ╔═╡ e0427619-2006-4644-9f47-be8a3461fad7
function solutions_to_df(solutions)
	rows = []
	for (problem, results) in pairs(solutions)
		for result in results
			push!(rows, (
				problem=problem,
				iterations=result.iterations,
				feasible=result.solution.feasible,
				total_cost=result.solution.total_cost,
				columns=result.solution.columns,
				row_feasibility=result.solution.row_feasibility,
			))
		end
	end
	DataFrame(rows)
end

# ╔═╡ fcc65c81-b3b8-4fb0-bddd-641a3fade42a
df_sa = solutions_to_df(sa_solutions)

# ╔═╡ 56c0a9bf-01a3-41de-aeb3-7d36a61c855a
df_bga = solutions_to_df(bga_solutions)

# ╔═╡ 67662b2a-808f-4424-8a59-b735814a8005
df_bga[df_bga.feasible, :]

# ╔═╡ 2f4b65d2-a82c-4ac4-b17b-8c6e401aaae7
df_ibga = solutions_to_df(ibga_solutions)

# ╔═╡ 3075ed6b-67f0-4d44-ba1f-e01758f46c8e
filter(
	[:problem, :feasible, :total_cost] =>
		(p, f, c) -> p == "data/sppnw41.txt" && f && c == 11307,
	df_ibga
)

# ╔═╡ d00afeb6-6695-4d9c-9f19-bc19d36c3362
function summary_stats(vals)
	isempty(vals) && return (n=0,unique=0,mean=NaN,std=NaN,min=NaN,max=NaN)
	return (
		n=length(vals),
		unique=length(unique(vals)),
		mean=mean(vals),
		std=std(vals),
		min=minimum(vals),
		max=maximum(vals),
	)
end

# ╔═╡ e8901293-c23f-4ba1-a505-d8924be01451
function analyse_runs(df::DataFrame)
	stats = combine(groupby(df, :problem; sort=true)) do sub
		all_cost = summary_stats(sub.total_cost)
		all_iterations = summary_stats(sub.iterations)
		feasible = sub[sub.feasible, :]
		feasible_cost = summary_stats(feasible.total_cost)

		return DataFrame(
			total = all_cost.n,
			unique = all_cost.unique,
			cost_best = all_cost.min,
			cost_worst = all_cost.max,
			cost_mean = all_cost.mean,
			cost_std = all_cost.std,
			f_total = feasible_cost.n,
			f_unique = feasible_cost.unique,
			f_cost_best = feasible_cost.min,
			f_cost_worst = feasible_cost.max,
			f_cost_mean = feasible_cost.mean,
			f_cost_std = feasible_cost.std,
			iterations_best = all_iterations.min,
			iterations_worst = all_iterations.max,
			iterations_mean = all_iterations.mean,
		)
	end
	return permutedims(stats, :problem, :metrics)
end

# ╔═╡ b480b9bb-66a2-4d76-b473-2f0f19b85924
df_sa_analysed = analyse_runs(df_sa)

# ╔═╡ 4cab7b17-d6a2-46e1-bb95-4353fa7ed254
df_bga_analysed = analyse_runs(df_bga)

# ╔═╡ 243985e5-519e-41fe-a850-1c8122aa500f
df_ibga_analysed = analyse_runs(df_ibga)

# ╔═╡ 9392f593-ad37-45ed-9a7e-917610dff502
function save_to_markdown_table_file(df, identifier)
	open("results-$identifier.md", "w") do io
		pretty_table(io, df, backend=:markdown, alignment=:c, formatters=[fmt__printf("%5.2f")])
	end
end

# ╔═╡ 3c2bc319-d142-45d9-8891-54b7d285f4b0
save_to_markdown_table_file(df_sa_analysed, "sa")

# ╔═╡ 0ef28849-3854-4017-9f8b-7c622e70eefa
save_to_markdown_table_file(df_bga_analysed, "bga")

# ╔═╡ 448c494f-aa66-4446-9293-b5eb3e09cf62
save_to_markdown_table_file(df_ibga_analysed, "ibga")

# ╔═╡ Cell order:
# ╟─f8abd002-86af-485a-b10d-c4915cfdd8eb
# ╠═941e2f78-4b72-4c57-8c70-7b650e429cf3
# ╠═22b7ae42-13fe-11f1-8a6b-4b014f10eaba
# ╠═e76196e4-d977-4c06-8b05-2f3c20c6397b
# ╠═cce8941a-f33c-410b-b6f4-13a5603f8de6
# ╠═c498c9f7-ad0f-48c7-bcbf-b6f0a2fd4185
# ╠═af9d07b5-9c97-47cd-9563-60f89b3b8d6a
# ╠═e0427619-2006-4644-9f47-be8a3461fad7
# ╠═fcc65c81-b3b8-4fb0-bddd-641a3fade42a
# ╠═56c0a9bf-01a3-41de-aeb3-7d36a61c855a
# ╠═67662b2a-808f-4424-8a59-b735814a8005
# ╠═2f4b65d2-a82c-4ac4-b17b-8c6e401aaae7
# ╠═3075ed6b-67f0-4d44-ba1f-e01758f46c8e
# ╠═abea3b54-bebb-4723-ac69-47b5023e4673
# ╠═d00afeb6-6695-4d9c-9f19-bc19d36c3362
# ╠═e8901293-c23f-4ba1-a505-d8924be01451
# ╠═b480b9bb-66a2-4d76-b473-2f0f19b85924
# ╠═4cab7b17-d6a2-46e1-bb95-4353fa7ed254
# ╠═243985e5-519e-41fe-a850-1c8122aa500f
# ╠═9392f593-ad37-45ed-9a7e-917610dff502
# ╠═3c2bc319-d142-45d9-8891-54b7d285f4b0
# ╠═0ef28849-3854-4017-9f8b-7c622e70eefa
# ╠═448c494f-aa66-4446-9293-b5eb3e09cf62
