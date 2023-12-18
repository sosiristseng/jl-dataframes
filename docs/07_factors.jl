#  # Working with CategoricalArrays

using DataFrames ## load package
using CategoricalArrays ## CategoricalArrays.jl is independent from DataFrames.jl but it is often used in combination

#  ## Constructor
# unordered
x = categorical(["A", "B", "B", "C"])
# ordered, by default order is sorting order
y = categorical(["A", "B", "B", "C"], ordered=true)
# unordered with missings
z = categorical(["A", "B", "B", "C", missing])
# ordered, into equal counts, possible to rename labels and give custom breaks
c = cut(1:10, 5)

#   (we will cover grouping later, but let us here use it to analyze the  results, we use Chain.jl for chaining)

using Chain

#---
@chain DataFrame(x=cut(randn(100000), 10)) begin
    groupby(:x)
    combine(nrow) ## just to make sure cut works right
end

#---
v = categorical([1, 2, 2, 3, 3]) ## contains integers not strings

#---
Vector{Union{String,Missing}}(z) ## sometimes you need to convert back to a standard vector

# ## Managing levels
arr = [x, y, z, c, v]

# check if categorical array is orderd
isordered.(arr)

# make x ordered
ordered!(x, true), isordered(x)

# and unordered again
ordered!(x, false), isordered(x)

# list levels
levels.(arr)

# missing will be included
unique.(arr)

# can compare as y is ordered
y[1] < y[2]

# not comparable, v is unordered although it contains integers
try
    v[1] < v[2]
catch e
    show(e)
end

# comparison against type underlying categorical value is not allowed
try
    y[2] < "A"
catch e
    show(e)
end

# you need to explicitly convert a value to a level
y[2] < CategoricalValue("A", y)

# but it is treated as a level, and thus only valid levels are allowed
try
    y[2] < CategoricalValue("Z", y)
catch e
    show(e)
end

# you can reorder levels, mostly useful for ordered CategoricalArrays
levels!(y, ["C", "B", "A"])

# observe that the order is changed
y[1] < y[2]

# you have to specify all levels that are present
try
    levels!(z, ["A", "B"])
catch e
    show(e)
end

# unless the underlying array allows for missings and force removal of levels
levels!(z, ["A", "B"], allowmissing=true)

# now z has only "B" entries
z[1] = "B"
z

# but it remembers the levels it had (the reason is mostly performance)
levels(z)

# this way we can clean it up
droplevels!(z)
levels(z)

# ##  Data manipulation
x, levels(x)

# new level added at the end (works only for unordered)
x[2] = "0"
x, levels(x)

#---
v, levels(v)

# even though the underlying data is Int, we cannot operate on it
try
    v[1] + v[2]
catch e
    show(e)
end

# you have either to retrieve the data by conversion (may be expensive)
Vector{Int}(v)

# or get a single value
unwrap(v[1]) + unwrap(v[2])

# this will work for arrays witout missings
unwrap.(v)

# also works on missing values
unwrap.(z)

# or do the conversion
Vector{Union{String,Missing}}(z)

# recode some values in an array; has also in place recode! equivalent
recode([1, 2, 3, 4, 5, missing], 1 => 10)

# here we provided a default value for not mapped recodings
recode([1, 2, 3, 4, 5, missing], "a", 1 => 10, 2 => 20)

# to recode Missing you have to do it explicitly
recode([1, 2, 3, 4, 5, missing], 1 => 10, missing => "missing")

#---
t = categorical([1:5; missing])
t, levels(t)

#---
recode!(t, [1, 3] => 2)
t, levels(t) ## note that the levels are dropped after recode

#---
t = categorical([1, 2, 3], ordered=true)
levels(recode(t, 2 => 0, 1 => -1)) ## and if you introduce a new levels they are added at the end in the order of appearance

#---
t = categorical([1, 2, 3, 4, 5], ordered=true) ## when using default it becomes the last level
levels(recode(t, 300, [1, 2] => 100, 3 => 200))

# ## Comparisons

x = categorical([1, 2, 3])
xs = [x, categorical(x), categorical(x, ordered=true), categorical(x, ordered=true)]
levels!(xs[2], [3, 2, 1])
levels!(xs[4], [2, 3, 1])
[a == b for a in xs, b in xs] ## all are equal - comparison only by contents

#---
signature(x::CategoricalArray) = (x, levels(x), isordered(x)) ## this is actually the full signature of CategoricalArray
# all are different, notice that x[1] and x[2] are unordered but have a different order of levels
[signature(a) == signature(b) for a in xs, b in xs]

# you cannot compare elements of unordered CategoricalArray
try
    x[1] < x[2]
catch e
    show(e)
end

# but you can do it for an ordered one
t[1] < t[2]

# isless works within the same CategoricalArray even if it is not ordered
isless(x[1], x[2])

# but not across categorical arrays
y = deepcopy(x)
try
    isless(x[1], y[2])
catch e
    show(e)
end

# you can use get to make a comparison of the contents of CategoricalArray
isless(unwrap(x[1]), unwrap(y[2]))

# equality tests works OK across CategoricalArrays
x[1] == y[2]

# ## Categorical columns in a DataFrame
df = DataFrame(x=1:3, y='a':'c', z=["a", "b", "c"])

# Convert all String columns to categorical in-place
transform!(df, names(df, String) => categorical, renamecols=false)

#---
describe(df)
