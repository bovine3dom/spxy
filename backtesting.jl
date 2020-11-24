### A Pluto.jl notebook ###
# v0.12.11

using Markdown
using InteractiveUtils

# ╔═╡ 99e1d6e6-20dc-11eb-06f2-d362ed6101e6
using Distributions, Random, Plots, Statistics, Dates, CSV, Query, DataFrames, TimeSeries

# ╔═╡ 96d476bc-20db-11eb-1cef-b97156feefc6
begin
	# Parameters
	spread = 1 # applied to mid-market price
	annual_swap_rate = 0.025
	trailing_stop = 0.02
	leverage = 2
	order_delay = 5 # minutes from trailing stop trigger to execution
end

# ╔═╡ c7190342-20db-11eb-03e8-0b3d03196bac
begin
	overnight_swap_rate = (1+annual_swap_rate)^(1/365)-1
	weekend_swap_rate = (1+overnight_swap_rate)^3 - 1
end

# ╔═╡ b466d7fa-20dc-11eb-1d1e-4b9f3d3c2fa8
begin
	Random.seed!(1337)
d = Normal()
end

# ╔═╡ ca43ab00-20dc-11eb-169b-035dc43b9bef
function gen_walk(steps=365*12) 
	diffs = rand(d,steps) * 2
	drift = (1.05)^(1/steps)
	result = [100.0]
	for t in 1:steps
		push!(result,result[t]*drift + diffs[t])
	end
	result
end

# ╔═╡ 81d10fc4-20df-11eb-1bd1-570e13122264
function strat(walk)
	perf = [1000.0]
	holding = perf[1] / walk[1]
	peak = walk[1]
	trough = walk[1]
	for t in 2:length(walk)
		peak = max(walk[t],peak)
		trough = min(walk[t],trough)
		fee = 0
		if walk[t] < (1-trailing_stop) * peak
			holding = 0
			trough = walk[t]
		end
		if (holding == 0) && (walk[t] > (1+trailing_stop)*trough)
			holding = perf[t-1] / walk[t]
			fee = holding * spread
			peak = walk[t]
		end
		swap = t % 12 == 0 ? overnight_swap_rate * perf[t-1] : 0
		push!(perf, perf[t-1] + (walk[t]-walk[t-1])*leverage*holding - fee - swap)
	end
	perf
end
		

# ╔═╡ bca82904-20dd-11eb-3cb1-9dd51fbe1448
mean(gen_walk()[end] for i in 1:1000)

# ╔═╡ 09092d00-20e3-11eb-11c8-47e5f9f89aa5
mean((gen_walk() |> strat)[end] for i in 1:1000)

# ╔═╡ 5775b26c-2e67-11eb-3033-8dcb60d80b31
# Actual data




# ╔═╡ aaa4baea-2e63-11eb-3282-0718d558e4f0
begin
	datafilenames = filter(endswith("csv"),readdir("data/histdata/spxusd"))
	minutedata = vcat((CSV.read("data/histdata/spxusd/" * f, DataFrame, header=["Time", "Open", "High", "Low", "Close", "Volume"], delim=";") for f in datafilenames)...)
	histdatafmt = Dates.DateFormat("yyyymmdd HHMMSS")
	minutedata[!,:Time] = Dates.DateTime.(minutedata[!,:Time],histdatafmt)
	sort!(minutedata,[:Time])
	minutedata
end

# ╔═╡ 70c305bc-2e67-11eb-1215-11810a9d5a21
#plot(minutedata[!,:Time], minutedata[!,:Open])

# ╔═╡ 8d32f752-2e67-11eb-11a0-a774f00516f3
begin
	# sketch of a little bot
	# for each timestep in market hours - can probably, for now, just use each row
	# look at t-5 minute price (if it doesn't exist, do nothing)
	# decide whether to buy/sell/do nothing
	# don't worry about swap etc. yet
end

# ╔═╡ 85a029ba-2e67-11eb-2603-39582a8300f2


# ╔═╡ 58ba73a4-2e69-11eb-2743-35183b2539fe
begin
# using TimeSeries
# z = TimeArray(minutedata, timestamp = :Time)
# # Pluto can't format these for display - maybe we don't care?
# # but the e.g. lag function would have been very useful.
end

# ╔═╡ f1062ecc-2e65-11eb-2a43-ddcac1153d74
minutedata[20,1] - Dates.Minute(5) # but TimeArrays will be indexed by the date, so it must be better to just use that instead. Otherwise we're re-inventing lots of wheels.

# ╔═╡ Cell order:
# ╠═96d476bc-20db-11eb-1cef-b97156feefc6
# ╠═c7190342-20db-11eb-03e8-0b3d03196bac
# ╠═99e1d6e6-20dc-11eb-06f2-d362ed6101e6
# ╠═b466d7fa-20dc-11eb-1d1e-4b9f3d3c2fa8
# ╠═ca43ab00-20dc-11eb-169b-035dc43b9bef
# ╠═81d10fc4-20df-11eb-1bd1-570e13122264
# ╠═bca82904-20dd-11eb-3cb1-9dd51fbe1448
# ╠═09092d00-20e3-11eb-11c8-47e5f9f89aa5
# ╠═5775b26c-2e67-11eb-3033-8dcb60d80b31
# ╠═aaa4baea-2e63-11eb-3282-0718d558e4f0
# ╠═70c305bc-2e67-11eb-1215-11810a9d5a21
# ╠═8d32f752-2e67-11eb-11a0-a774f00516f3
# ╟─85a029ba-2e67-11eb-2603-39582a8300f2
# ╠═58ba73a4-2e69-11eb-2743-35183b2539fe
# ╠═f1062ecc-2e65-11eb-2a43-ddcac1153d74
