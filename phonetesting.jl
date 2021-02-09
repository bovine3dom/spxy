using Random, UnicodePlots, Statistics, Dates, CSV, Query, DataFrames, TimeSeries

datafilenames = filter(endswith("csv"),readdir("data/histdata/spxusd"))
minutedata = vcat((CSV.read("data/histdata/spxusd/" * f, DataFrame, header=["Time", "Open", "High", "Low", "Close", "Volume"], delim=";") for f in datafilenames)...)
histdatafmt = Dates.DateFormat("yyyymmdd HHMMSS")
minutedata[!,:Time] = Dates.DateTime.(minutedata[!,:Time],histdatafmt)
sort!(minutedata,[:Time])  #required for timeseries.jl
#minutedata

#lineplot(minutedata[!,:Time], minutedata[!,:Open])

# sketch of a little bot
# for each timestep in market hours - can probably, for now, just use each row
# look at t-5 minute price (if it doesn't exist, do nothing)
# decide whether to buy/sell/do nothing
# don't worry about swap etc. yet



using TimeSeries
z = TimeArray(minutedata, timestamp = :Time)
#upto(maximum, z)
#?basecall
# # but the e.g. lag function would have been very useful.

#= minutedata[20,1] - Dates.Minute(5) # but TimeArrays will be indexed by the date, so it must be better to just use that instead. Otherwise we're re-inventing lots of wheels. =#
#

t(ta) = getfield(ta,:timestamp)
# oldest value closest to date
function interpolate(timeseries,date::DateTime)
    timeseries[date - Dates.Day(3) : Dates.Minute(1): date][end]
end

function hourly(d::DateTime)
    minute(d) == 0 && millisecond(d) == 0
end
# m = when(when(z, hourly, true), hour, 12)  # smaller version for playing with
m = when(z, hourly, true)

# getfield(z, :timestamp) is apparently the easiest way to get the times out
function timeplot(t::TimeArray, f)
    lineplot(getfield(t,:timestamp), getfield(t[f],:values))
end

timeplot(moving(maximum, when(when(z, hourly, true), hour, 12), 14), :Open)
timeplot(upto(maximum, when(when(z, hourly, true), hour, 12)),:Open)

# Sketch for N year return distribution
# boxplot
#
# for every day in the range up until the end - N years
# interpolate to day + N years, find percent return, add to array
# boxplot of that array

function period_returns(ta, p; comp = ta)
    percs = Float64[]
    for r in eachrow(ta[t(ta[1])[1]:Dates.Minute(1):t(ta[end])[1] - p])
        # todo: maybe worry about this? interpolate could fail over holidays
        try
        push!(percs, values(interpolate(comp,r.timestamp + p))[1]/ values(r)[2] - 1)
    catch(e)
        ;
      end
    end
    percs
end
n_year_returns(ta,N) = period_returns(ta, Year(N))
boxplot(n_year_returns(m.Open,5))
boxplot(n_year_returns(m.Open,3))
boxplot(n_year_returns(m.Open,1))
boxplot(period_returns(m.Open,Month(1)))

# So, lay summary for Mum
#
# After 5 years, can expect 60% return. Around half the time you'd get between 50% and 75%. Most you could expect is 100% and least ~10%.
# 3 years: 35% return, 25% - 45% normal. 80% very lucky, minus 3% extremely unlucky
# 1 month: 1.5% return, minus 1%  - +3% normal. 25% very lucky, minus 30% incredibly unlucky
#

# For me
# Worst daily drop -6%. Expect 0.8% drop about once a fortnight
# Implies that 10x leverage is pretty safe (risking a margin call)
# 
# VVVVVVV
# VVVVVVV
# VVVVVVV
# VVVVVVV
# VVVVVVV
# NB!!! Need to triple check this on minute level data once I have access to a beefier machine!
# ^^^^^^^
# ^^^^^^^
# ^^^^^^^
# ^^^^^^^
# ^^^^^^^
# ^^^^^^^

# If we only consider ATHs instead, it doesn't make much difference
M = upto(maximum, m.Open)
aths = m.Open[findwhen(m.Open .>= M)]
boxplot(period_returns(aths, Year(1), comp=m.Open))
boxplot(period_returns(m.Open, Year(1))


# for margin, care about maximum fall
# so rather than interpolate as the numerator we want basecall(accumulate(min ...), to( ...))
#   # roughly 1000x quicker than upto... best to avoid upto!
    # basecall(m.Open, x->accumulate(min,x))
#

# todo: combine this with the function above
function worst_returns(ta, p; comp = ta)
    percs = Float64[]
    for r in eachrow(ta[t(ta[1])[1]:Dates.Minute(1):t(ta[end])[1] - p])
        # todo: maybe worry about this? interpolate could fail over holidays
        try
            push!(percs, values(minimum(to(from(comp, r.timestamp),r.timestamp + p)))[1]/ values(r)[2] - 1)
    catch(e)
        ;
      end
    end
    percs
end

# # If we're holding S&P for a week, looking at hourly data
# # 10% drawdown fall 1 in 100 days, 15% once every three years
# quantile(worst_returns(m.Open,Week(1)),0.01) 
#
# # For 2 weeks, it's 23% once every three years. Reduces to 19% if we look at daily data
#
# So, optimally, let's say 30% loss wipes us out at most.
#
# Returns greater than 12% almost never happen (+ 1 in 3 years) so don't bother paying to benefit from them.
#
# So I think a decent strategy is this: aim for 10x leverage up to 10% and 3x leverage down to -30%? Get 2-week options.
