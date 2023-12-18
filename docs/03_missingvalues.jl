# # Handling missing values
# A singelton type `Missing` allows us to deal with missing values.

using DataFrames

#---
missing, typeof(missing)

# Arrays automatically create an appropriate union type.
x = [1, 2, missing, 3]

# `ismissing` checks if passed value is missing.
ismissing(1), ismissing(missing), ismissing(x), ismissing.(x)

# We can extract the type combined with Missing from a `Union` via `nonmissingtype` (This is useful for arrays!)

eltype(x), nonmissingtype(eltype(x))

# `missing` comparisons produce `missing`.
missing == missing, missing != missing, missing < missing

# This is also true when `missing`s are compared with values of other types.
1 == missing, 1 != missing, 1 < missing

# `isequal`, `isless`, and `===` produce results of type `Bool`. Notice that `missing` is considered greater than any numeric value.
isequal(missing, missing), missing === missing, isequal(1, missing), isless(1, missing)

# In the next few examples, we see that many (not all) functions handle `missing`.
map(x -> x(missing), [sin, cos, zero, sqrt]) ## part 1

#---
map(x -> x(missing, 1), [+, -, *, /, div]) ## part 2

#---
using Statistics ## needed for mean
map(x -> x([1, 2, missing]), [minimum, maximum, extrema, mean, float]) ## part 3

# `skipmissing` returns iterator skipping missing values. We can use `collect` and `skipmissing` to create an array that excludes these missing values.

collect(skipmissing([1, missing, 2, missing]))

# Here we use `replace` to create a new array that replaces all missing values with some value (`NaN` in this case).
replace([1.0, missing, 2.0, missing], missing => NaN)

# Another way is to use `coalesce()`
coalesce.([1.0, missing, 2.0, missing], NaN)

# You can also use `recode` from CategoricalArrays.jl if you have a default output value.
using CategoricalArrays
recode([1.0, missing, 2.0, missing], false, missing => true)

# There are also `replace!` and `recode!` functions that work in place.
# Here is an example how you can to missing inputation in a data frame.
df = DataFrame(a=[1, 2, missing], b=["a", "b", missing])

# we change `df.a` vector in place.
replace!(df.a, missing => 100)

# Now we overwrite `df.b` with a new vector, because the replacement type is different than what `eltype(df.b)` accepts.
df.b = coalesce.(df.b, 100)

#---
df

# You can use `unique` or `levels` to get unique values with or without missings, respectively.
unique([1, missing, 2, missing]), levels([1, missing, 2, missing])

# In this next example, we convert `x` to `y` with `allowmissing`, where `y` has a type that accepts missings.
x = [1, 2, 3]
y = allowmissing(x)

# Then, we convert back with `disallowmissing`. This would fail if `y` contained missing values!
z = disallowmissing(y)
x, y, z

# `disallowmissing` has `error` keyword argument that can be used to decide how it should behave when it encounters a column that actually contains a `missing` value
df = allowmissing(DataFrame(ones(2, 3), :auto))

#---
df[1, 1] = missing

#---
df

# an error is thrown

try
    disallowmissing(df)
catch e
    show(e)
end

# column `:x1` is left untouched as it contains missing
disallowmissing(df, error=false)

# In this next example, we show that the type of each column in `x` is initially `Int64`. After using `allowmissing!` to accept missing values in columns 1 and 3, the types of those columns become `Union{Int64,Missing}`.

x = DataFrame(rand(Int, 2, 3), :auto)
println("Before: ", eltype.(eachcol(x)))
allowmissing!(x, 1) ## make first column accept missings
allowmissing!(x, :x3) ## make :x3 column accept missings
println("After: ", eltype.(eachcol(x)))

# In this next example, we'll use `completecases` to find all the rows of a `DataFrame` that have complete data.
x = DataFrame(A=[1, missing, 3, 4], B=["A", "B", missing, "C"])

#---
println("Complete cases:\n", completecases(x))

# We can use `dropmissing` or `dropmissing!` to remove the rows with incomplete data from a `DataFrame` and either create a new `DataFrame` or mutate the original in-place.
y = dropmissing(x)
dropmissing!(x)

#---
x

#---
y

# When we call `describe` on a `DataFrame` with dropped missing values, the columns do not allow missing values any more by default.
describe(x)

# Alternatively you can pass `disallowmissing` keyword argument to `dropmissing` and `dropmissing!`
x = DataFrame(A=[1, missing, 3, 4], B=["A", "B", missing, "C"])

#---
dropmissing!(x, disallowmissing=false)

#===
## Making functions `missing`-aware

If we have a function that does not handle `missing` values we can wrap it using `passmissing` function so that if any of its positional arguments is missing we will get a `missing` value in return. In the example below we change how `string` function behaves:
===#
string(missing)

#---
string(missing, " ", missing)

#---
string(1, 2, 3)

#---
lift_string = passmissing(string)

#---
lift_string(missing)

#---
lift_string(missing, " ", missing)

#---
lift_string(1, 2, 3)

# ## Aggregating rows containing missing values
# Create an example data frame containing missing values:
df = DataFrame(a=[1, missing, missing], b=[1, 2, missing])

# If we just run `sum` on the rows we get two missing entries:
sum.(eachrow(df))

# One can apply `skipmissing` on the rows to avoid this problem:
try
    sum.(skipmissing.(eachrow(df)))
catch e
    show(e)
end

# However, we get an error. The problem is that the last row of `df` contains only missing values, and since `eachrow` is type unstable the `eltype` of the result of `skipmissing` is unknown (so it is marked `Any`)
collect(skipmissing(eachrow(df)[end]))

# In such cases it is useful to switch to `Tables.namedtupleiterator` which is type stable as discussed in 01_constructors.ipynb notebook.
sum.(skipmissing.(Tables.namedtupleiterator(df)))

# Later in the tutorial you will learn that you can efficiently calculate such sums using the `select` function:
select(df, AsTable(:) => ByRow(sum ∘ skipmissing))

# Note that it correctly handles the rows with all missing values.
