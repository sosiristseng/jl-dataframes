#   # Manipulating rows of DataFrame
#   ## Selecting rows

using DataFrames
using Statistics
using Random
Random.seed!(1);

#---
df = DataFrame(rand(4, 5), :auto)

#   using `:` as row selector will copy columns
df[:, :]

#   this is the same as
copy(df)

#   you can get a subset of rows of a data frame without copying using `view` to get a `SubDataFrame`
sdf = view(df, 1:3, 1:3)

#   you still have a detailed reference to the parent
parent(sdf), parentindices(sdf)

#   selecting a single row returns a `DataFrameRow` object which is also a view
dfr = df[3, :]

#---
parent(dfr), parentindices(dfr), rownumber(dfr)

#   let us add a column to a data frame by assigning a scalar broadcasting
df[!, :Z] .= 1

#---
df

#   Earlier we used : for column selection in a view (`SubDataFrame` and `DataFrameRow`). In this case a view will have all columns of the parent after the parent is mutated.
dfr

#---
parent(dfr), parentindices(dfr), rownumber(dfr)

#   Note that `parent` and `parentindices` refer to the true source of data for a `DataFrameRow` and `rownumber` refers to row number in the direct object that was used to create `DataFrameRow`

df = DataFrame(a=1:4)

#---
dfv = view(df, [3, 2], :)

#---
dfr = dfv[1, :]

#---
parent(dfr), parentindices(dfr), rownumber(dfr)

# ## Reordering rows
#   We create some random data frame (and hope that x.x is not sorted :), which is quite likely with 12 rows)
x = DataFrame(id=1:12, x=rand(12), y=[zeros(6); ones(6)])

#   check if a DataFrame or a subset of its columns is sorted
issorted(x), issorted(x, :x)

#   we sort x in place
sort!(x, :x)

#   now we create a new DataFrame
y = sort(x, :id)

#   here we sort by two columns, first is decreasing, second is increasing
sort(x, [:y, :x], rev=[true, false])

#---
sort(x, [order(:y, rev=true), :x]) ## the same as above

# now we try some more fancy sorting stuff
sort(x, [order(:y, rev=true), order(:x, by=v -> -v)])

#   this is how you can reorder rows (here randomly)
x[shuffle(1:10), :]
#   it is also easy to swap rows using broadcasted assignment

sort!(x, :id)
x[[1, 10], :] .= x[[10, 1], :]
x

# ## Merging/adding rows
x = DataFrame(rand(3, 5), :auto)

#   merge by rows - data frames must have the same column names; the same is `vcat`
[x; x]

#   you can efficiently `vcat` a vector of `DataFrames` using `reduce`
reduce(vcat, [x, x, x])

#   get `y` with other order of names
y = x[:, reverse(names(x))]

#   `vcat` is still possible as it does column name matching
vcat(x, y)

# but column names must still match
try
    vcat(x, y[:, 1:3])
catch e
    show(e)
end

# unless you pass `:intersect`, `:union` or specific column names as keyword argument `cols`

vcat(x, y[:, 1:3], cols=:intersect)

#---
vcat(x, y[:, 1:3], cols=:union)

#---
vcat(x, y[:, 1:3], cols=[:x1, :x5])

# append!` modifies `x` in place
append!(x, x)

# here column names must match exactly unless `cols` keyword argument is passed
append!(x, y)

# standard `repeat` function works on rows; also `inner` and `outer` keyword arguments are accepted
repeat(x, 2)

#   `push!` adds one row to `x` at the end; one must pass a correct number of values unless `cols` keyword argument is passed
push!(x, 1:5)
x

#   also works with dictionaries
push!(x, Dict(:x1 => 11, :x2 => 12, :x3 => 13, :x4 => 14, :x5 => 15))
x

#   and `NamedTuples` via name matching
push!(x, (x2=2, x1=1, x4=4, x3=3, x5=5))

#   and `DataFrameRow` also via name matching
push!(x, x[1, :])

#===
Please consult the documentation of `push!`, `append!` and `vcat` for allowed values of `cols` keyword argument.
This keyword argument governs the way these functions perform column matching of passed arguments. Also `append!` and `push!` support a `promote` keyword argument that decides if column type promotion is allowed.

Let us here just give a quick example of how heterogeneous data can be stored in the data frame using these functionalities:
===#
source = [(a=1, b=2), (a=missing, b=10, c=20), (b="s", c=1, d=1)]

#---
df = DataFrame()

#---
for row in source
    push!(df, row, cols=:union) ## if cols is :union then promote is true by default
end

#---
df

#   and we see that `push!` dynamically added columns as needed and updated their element types
#  ### Subsetting/removing rows
x = DataFrame(id=1:10, val='a':'j')

# by using indexing
x[1:2, :]

# a single row selection creates a `DataFrameRow`
x[1, :]

# but this is a `DataFrame`
x[1:1, :]

# the same but a view
view(x, 1:2, :)

# selects columns 1 and 2
view(x, :, 1:2)

# indexing by Bool, exact length math is required
x[repeat([true, false], 5), :]

# alternatively we can also create a view
view(x, repeat([true, false], 5), :)

# we can delete one row in place
deleteat!(x, 7)

#   or a collection of rows, also in place
deleteat!(x, 6:7)

#   you can also create a new DataFrame when deleting rows using Not indexing
x[Not(1:2), :]

#---
x

# now we move to row filtering
x = DataFrame([1:4, 2:5, 3:6], :auto)
#   create a new `DataFrame` where filtering function operates on `DataFrameRow`
filter(r -> r.x1 > 2.5, x)

#---
filter(r -> r.x1 > 2.5, x, view=true) # the same but as a view

#  or
filter(:x1 => >(2.5), x)

# in place modification of `x`, an example with `do`-block syntax

filter!(x) do r
    if r.x1 > 2.5
        return r.x2 < 4.5
    end
    r.x3 < 3.5
end

#   A common operation is selection of rows for which a value in a column is contained in a given set. Here are a few ways in which you can achieve this.
df = DataFrame(x=1:12, y=mod1.(1:12, 4))

# We select rows for which column `y` has value `1` or `4`.

filter(row -> row.y in [1, 4], df)

#---
filter(:y => in([1, 4]), df)

#---
df[in.(df.y, Ref([1, 4])), :]

#   DataFrames.jl also provides a subset function that works on whole columns and allows for multiple conditions:

x = DataFrame([1:4, 2:5, 3:6], :auto)

#---
subset(x, :x1 => x -> x .< mean(x), :x2 => ByRow(<(2.5)))

#   Similarly an in-place `subset!` function is provided.

#  ## Deduplicating
x = DataFrame(A=[1, 2], B=["x", "y"])
append!(x, x)
x.C = 1:4
x

#   get first unique rows for given index
unique(x, [1, 2])

#   now we look at whole rows
unique(x)

#   get indicators of non-unique rows
nonunique(x, :A)

#   modify `x` in place
unique!(x, :B)

#  ## Extracting one row from a DataFrame into standard collections
x = DataFrame(x=[1, missing, 2], y=["a", "b", missing], z=[true, false, true])

#---
cols = [:y, :z]

# you can use a conversion to a `Vector` or an `Array`

Vector(x[1, cols])

#---
Array(x[1, cols]) ## the same

#   now you will get a vector of vectors
[Vector(x[i, cols]) for i in axes(x, 1)]

#   it is easy to convert a `DataFrameRow` into a `NamedTuple`
copy(x[1, cols])

#   or a `Tuple`
Tuple(x[1, cols])

#  ## Working with a collection of rows of a data frame
#  You can use eachrow to get a vector-like collection of DataFrameRows

df = DataFrame(reshape(1:12, 3, 4), :auto)

#---
er_df = eachrow(df)

#---
er_df[1]

#---
last(er_df)

#---
er_df[end]

#   As DataFrameRows objects keeps connection to the parent data frame you can get the columns of the parent using getproperty
er_df.x1

#  ## Flattening a data frame
#   Occasionally you have a data frame whose one column is a vector of  collections. You can expand (flatten) such a column using the flatten  function

df = DataFrame(a='a':'c', b=[[1, 2, 3], [4, 5], 6])

#---
flatten(df, :b)

#  ## Only one row
#  `only` from Julia Base is also supported in DataFrames.jl and succeeds if the data frame has only one row, in which case it is returned.

df = DataFrame(a=1)

#---
only(df)

#---
df2 = repeat(df, 2)

#---
try
    only(df2)
catch e
    show(e)
end
