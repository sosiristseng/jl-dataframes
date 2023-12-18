#  # DataFrames Extras
#   Selected functionalities/packages

using DataFrames
using CategoricalArrays

# ## Frequency Tables
# https://github.com/nalimilan/FreqTables.jl

using FreqTables

#---
df = DataFrame(a=rand('a':'d', 1000), b=rand(["x", "y", "z"], 1000))
ft = freqtable(df, :a, :b) ## observe that dimensions are sorted if possible

# you can index the result using numbers or names
ft[1,1], ft['b', "z"]

# getting proportions - 1 means we want to calculate them in rows (first dimension)
prop(ft, margins=1)

# and columns are normalized to 1.0 now
prop(ft, margins=2)

#---
x = categorical(rand(1:3, 10))
levels!(x, [3, 1, 2, 4]) ## reordering levels and adding an extra level
freqtable(x) ## order is preserved and not-used level is shown

# by default missings are listed
freqtable([1,1,2,3,missing])

# but we can skip them
freqtable([1,1,2,3,missing], skipmissing=true)

#---
df = DataFrame(a=rand(3:4, 1000), b=rand(5:6, 1000))
ft = freqtable(df, :a, :b) # now dimensions are numbers

# this is an error - standard array indexing takes precedence
try
    ft[3,5]
catch e
    show(e)
end

# you have to use Name() wrapper
ft[Name(3), Name(5)]

# ## DataFramesMeta.jl
# [DataFramesMeta.jl](https://github.com/JuliaData/DataFramesMeta.jl) provides a more terse syntax due to the benefits of metaprogramming.

using DataFramesMeta

#---
df = DataFrame(x=1:8, y='a':'h', z=repeat([true,false], outer=4))

# expressions with columns of DataFrame
@with(df, :x + :z)

# you can define code blocks
@with df begin
    a = :x[:z]
    b = :x[.!:z]
    :y + [a; b]
end

#  `@with` creates hard scope so variables do not leak out
df2 = DataFrame(a = [:a, :b, :c])
@with(df2, :a .== ^(:a)) ## sometimes we want to work on a raw Symbol, ^() escapes it

#---
x_str = "x"
y_str = "y"
df2 = DataFrame(x=1:3, y=4:6, z=7:9)
## $expression inderpolates the expression in-place; in particular this way you can use column names passed as strings
@with(df2, $x_str + $y_str)

# a very useful macro for filtering
@subset(df, :x .< 4, :z .== true)

# create a new DataFrame based on the old one
@select(df, :x, :y = 2*:x, :z=:y)

# create a new DataFrame adding columns based on the old one
@transform(df, :x = 2*:x, :y = :x)

# sorting into a new data frame, less powerful than sort, but lightweight
@orderby(df, :z, -:x)

# ### Chaining operations
# https://github.com/jkrumbiegel/Chain.jl
using Chain

# chaining of operations on DataFrame
@chain df begin
    @subset(:x .< 5)
    @orderby(:z)
    @transform(:x² = :x .^ 2)
    @select(:z, :x, :x²)
end

# ### Working on grouped DataFrame
df = DataFrame(a = 1:12, b = repeat('a':'d', outer=3))

#---
g = groupby(df, :b)

#---
using Statistics

# groupby+combine in one shot
@by(df, :b, :first = first(:a), :last = last(:a), :mean = mean(:a))

# the same as by but on grouped DataFrame
@combine(g, :first = first(:a), :last = last(:a), :mean = mean(:a))

# similar in DataFrames.jl - we use auto-generated column names
combine(g, :a .=> [first, last, mean])

# perform operations within a group and return ungrouped DataFrame
@transform(g, :center = mean(:a), :centered = :a .- mean(:a))

# this is defined in DataFrames.jl
DataFrame(g)

# actually this is not the same as DataFrame() as it perserves the original row order
@transform(g)

# ### Rowwise operations on DataFrame
df = DataFrame(a = 1:12, b = repeat(1:4, outer=3))

# such conditions are often needed but are complex to write
@transform(df, :x = ifelse.((:a .> 6) .& (:b .== 4), "yes", "no"))

# one option is to use a function that works on a single observation and broadcast it
myfun(a, b) = a > 6 && b == 4 ? "yes" : "no"
@transform(df, :x = myfun.(:a, :b))

# or you can use @eachrow macro that allows you to process DataFrame rowwise
@eachrow df begin
   @newcol :x::Vector{String}
    :x = :a > 6 && :b == 4 ? "yes" : "no"
end

# In `DataFramses.jl` you would write this as:

transform(df, [:a, :b] => ByRow((a,b) -> ifelse(a > 6 && b == 4, "yes", "no")) => :x)

# You can also use eachrow from DataFrames to perform the same transformation. However `@eachrow` will be faster than the operation below.

df2 = copy(df)
df2.x = Vector{String}(undef, nrow(df2))
for row in eachrow(df2)
   row[:x] = row[:a] > 6 && row[:b] == 4 ? "yes" : "no"
end
df2

# ## StatsPlots.jl: Visualizing data
#   https://github.com/JuliaPlots/StatsPlots.jl

using StatsPlots ## you might need to setup Plots package and some plotting backend first

# A showcase of StatsPlots.jl functions

using Random
Random.seed!(1)
df = DataFrame(x = sort(randn(1000)), y=randn(1000), z = [fill("b", 500); fill("a", 500)]);

# a most basic plot
@df df plot(:x, :y, legend=:topleft, label="y(x)")

# density plot
@df df density(:x, label="")

# and a histogram
@df df histogram(:y, label="y")

# the warning is likely to be removed in future releases of plotting packages
@df df boxplot(:z, :x, label="x")

# Violin plot
@df df violin(:z, :y, label="y")
