# # Transformation to DataFrames
# Split-apply-combine
using DataFrames

# ##  Grouping a dat=a frame
x = DataFrame(id=[1, 2, 3, 4, 1, 2, 3, 4], id2=[1, 2, 1, 2, 1, 2, 1, 2], v=rand(8))

#---
groupby(x, :id)

#---
groupby(x, [])

#---
gx2 = groupby(x, [:id, :id2])

# get the parent DataFrame
parent(gx2)

# back to the DataFrame, but in a different order of rows than the original
vcat(gx2...)

# the same
DataFrame(gx2)

# drop grouping columns when creating a data frame
DataFrame(gx2, keepkeys=false)

# vector of names of grouping variables
groupcols(gx2)

# and non-grouping variables
valuecols(gx2)

# group indices in parent(gx2)
groupindices(gx2)

#---
kgx2 = keys(gx2)

#  You can index into a `GroupedDataFrame` like to a vector or to a dictionary. The second form acceps `GroupKey`, `NamedTuple` or a `Tuple`
gx2

#---
k = keys(gx2)[1]

#---
ntk = NamedTuple(k)

#---
tk = Tuple(k)

# the operations below produce the same result and are fast
gx2[1]

#---
gx2[k]

#---
gx2[ntk]

#---
gx2[tk]

# handling missing values

x = DataFrame(id=[missing, 5, 1, 3, missing], x=1:5)

# by default groups include mising values and their order is not guaranteed
groupby(x, :id)

# but we can change it; now they are sorted
groupby(x, :id, sort=true, skipmissing=true)

# and now they are in the order they appear in the source data frame
groupby(x, :id, sort=false)

# ## Performing transformations
# by group using combine, select, select!, transform, and transform!
using Statistics
using Chain

# reduce the number of rows in the output
ENV["LINES"] = 15

#---
x = DataFrame(id=rand('a':'d', 100), v=rand(100))

# apply a function to each group of a data frame combine keeps as many rows as are returned from the function
@chain x begin
    groupby(:id)
    combine(:v => mean)
end

#---
x.id2 = axes(x, 1)

# select and transform keep as many rows as are in the source data frame and in correct order
# additionally transform keeps all columns from the source

@chain x begin
    groupby(:id)
    transform(:v => mean)
end

# note that combine reorders rows by group of GroupedDataFrame
@chain x begin
    groupby(:id)
    combine(:id2, :v => mean)
end

# we give a custom name for the result column
@chain x begin
    groupby(:id)
    combine(:v => mean => :res)
end

# you can have multiple operations
@chain x begin
    groupby(:id)
    combine(:v => mean => :res1, :v => sum => :res2, nrow => :n)
end

#===
Additional notes:
* `select!` and `transform!` perform operations in-place
* The general syntax for transformation is `source_columns => function => target_column`
* if you pass multiple columns to a function they are treated as positional arguments
* `ByRow` and `AsTable` work exactly like discussed for operations on data frames in 05_columns.ipynb
* you can automatically groupby again the result of `combine`, `select` etc. by passing `ungroup=false` keyword argument to them
* similarly `keepkeys` keyword argument allows you to drop grouping columns from the resulting data frame

It is also allowed to pass a function to all these functions (also - as a special case, as a first argument). In this case the return value can be a table. In particular it allows for an easy dropping of groups if you return an empty table from the function.

If you pass a function you can use a `do` block syntax. In case of passing a function it gets a `SubDataFrame` as its argument.

Here is an example:
===#
combine(groupby(x, :id)) do sdf
    n = nrow(sdf)
    n < 25 ? DataFrame() : DataFrame(n=n) ## drop groups with low number of rows
end

# You can also produce multiple columns in a single operation, e.g.:

df = DataFrame(id=[1, 1, 2, 2], val=[1, 2, 3, 4])

#---
@chain df begin
    groupby(:id)
    combine(:val => (x -> [x]) => AsTable)
end

#---
@chain df begin
    groupby(:id)
    combine(:val => (x -> [x]) => [:c1, :c2])
end

#  t is easy to unnest the column into multiple columns, e.g.

df = DataFrame(a=[(p=1, q=2), (p=3, q=4)])

#---
select(df, :a => AsTable)

#---
df = DataFrame(a=[[1, 2], [3, 4]])

# automatic column names generated
select(df, :a => AsTable)

# custom column names generated
select(df, :a => [:C1, :C2])

# Finally, observe that one can conveniently apply multiple transformations using broadcasting:

df = DataFrame(id=repeat(1:10, 10), x1=1:100, x2=101:200)

#---
@chain df begin
    groupby(:id)
    combine([:x1, :x2] .=> minimum)
end

#---
@chain df begin
    groupby(:id)
    combine([:x1, :x2] .=> [minimum maximum])
end

# ## Aggregation of a data frame using mapcols
x = DataFrame(rand(10, 10), :auto)

#---
mapcols(mean, x)

# ## Mapping rows and columns using eachcol and eachrow
# map a function over each column and return a vector
map(mean, eachcol(x))

# an iteration returns a Pair with column name and values
foreach(c -> println(c[1], ": ", mean(c[2])), pairs(eachcol(x)))

# now the returned value is DataFrameRow which works as a NamedTuple but is a view to a parent DataFrame
map(r -> r.x1 / r.x2, eachrow(x))

# it prints like a data frame, only the caption is different so that you know the type of the object
er = eachrow(x)

er.x1 # you can access columns of a parent data frame directly

# it prints like a data frame, only the caption is different so that you know the type of the object
ec = eachcol(x)

# you can access columns of a parent data frame directly
ec.x1

# ## Transposing
#  you can transpose a data frame using permutedims:

df = DataFrame(reshape(1:12, 3, 4), :auto)

#---
df.names = ["a", "b", "c"]

#---
permutedims(df, :names)

# revert the changes for line width
delete!(ENV, "LINES")
