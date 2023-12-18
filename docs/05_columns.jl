#   # Manipulating columns of a DataFrame
#   ## Renaming columns
#   Let's start with a DataFrame of Bools that has default column names.

using DataFrames

#---
x = DataFrame(rand(Bool, 3, 4), :auto)

#   With rename, we create new DataFrame; here we rename the column :x1 to :A.
#   (rename also accepts collections of Pairs.)

rename(x, :x1 => :A)

#   With rename! we do an in place transformation.
#   This time we've applied a function to every column name (note that the function gets a column names as a string).

rename!(c -> c^2, x)

#   We can also change the name of a particular column without knowing the
#   original.
#   Here we change the name of the third column, creating a new DataFrame.

rename(x, 3 => :third)

#   If we pass a vector of names to rename!, we can change the names of all
#   variables.

rename!(x, [:a, :b, :c, :d])

#   In all the above examples you could have used strings instead of symbols,
#   e.g.

rename!(x, string.('a':'d'))

#   rename! allows for circular renaming of columns, e.g.:
x

#---
rename!(x, "a"=>"d", "d"=>"a")

#   We get an error when we try to provide duplicate names
try
    rename(x, fill(:a, 4))
catch e
    show(e)
end

#   unless we pass makeunique=true, which allows us to handle duplicates in passed names.

rename(x, fill(:a, 4), makeunique=true)

#   ## Reordering columns
#   We can reorder the names(x) vector as needed, creating a new DataFrame.

using Random
Random.seed!(1234)
x[:, shuffle(names(x))]

#   Also select! can be used to achieve this in place (or select to perform a copy):
x

#---
select!(x, 4:-1:1);
x

#   ## Merging/adding columns

x = DataFrame([(i,j) for i in 1:3, j in 1:4], :auto)

#   With `hcat` we can merge two `DataFrames`. Also `[x y]` syntax is supported but only when DataFrames have unique column names.
hcat(x, x, makeunique=true)

#   You can append a vector to a data frame with the following syntax:
y = [x DataFrame(A=[1,2,3])]

#   Here we do the same but add column `:A` to the front.
y = [DataFrame(A=[1,2,3]) x]

#   A column can also be added in the middle. Here a brute-force method is used and a new `DataFrame` is created.

using BenchmarkTools
@btime [$x[!, 1:2] DataFrame(A=[1,2,3]) $x[!, 3:4]]

#   We could also do this with a specialized in place method `insertcols!`. Let's add `:newcol` to the `DataFrame` y.

insertcols!(y, 2, "newcol" => [1,2,3])

#   If you want to insert the same column name several times `makeunique=true` is  needed as usual.

insertcols!(y, 2, :newcol => [1,2,3], makeunique=true)

#   We can see how much faster it is to insert a column with `insertcols!` than with `hcat` using `@btime` (note that we use here a `Pair` notation as an example).

@btime insertcols!(copy($x), 3, :A => [1,2,3])

#   Let's use `insertcols!` to append a column in place (note that we dropped the index at which we insert the column)

insertcols!(x, :A => [1,2,3])

#   and to in place prepend a column.

insertcols!(x, 1, :B => [1,2,3])

#   Note that `insertcols!` can be used to insert several columns to a data frame at once and that it performs broadcasting if needed:

df = DataFrame(a = [1, 2, 3])

#---
insertcols!(df, :b => "x", :c => 'a':'c', :d => Ref([1,2,3]))

#   Interestingly we can emulate `hcat` mutating the data frame in-place using `insertcols!`:

df1 = DataFrame(a=[1,2])

#---
df2 = DataFrame(b=[2,3], c=[3,4])

#---
hcat(df1, df2)

#---
df1 ## df1 is not touched

#---
insertcols!(df1, pairs(eachcol(df2))...)

#---
df1 ## now we have changed df1

#  ## Subsetting/removing columns
#  Let's create a new `DataFrame` `x` and show a few ways to create DataFrames with a subset of `x`'s columns.

x = DataFrame([(i,j) for i in 1:3, j in 1:5], :auto)

#   First we could do this by index:

x[:, [1,2,4,5]] ## use ! instead of : for non-copying operation

#   or by column name:

x[:, [:x1, :x4]]

#   We can also choose to keep or exclude columns by `Bool` (we need a vector whose length is the number of columns in the original `DataFrame`).

x[:, [true, false, true, false, true]]

#   Here we create a single column `DataFrame`,

x[:, [:x1]]

#   and here we access the vector contained in column `:x1`.

x[!, :x1] ## use : instead of ! to copy

#---
x.x1 ## the same

#   We could grab the same vector by column number

x[!, 1]

#   Note that getting a single column returns it without copying while creating a new `DataFrame` performs a copy of the column

x[!, 1] === x[!, [1]]

#   you can also use `Regex`, `All`, `Between` and `Not` from InvertedIndies.jl for  column selection:
x[!, r"[12]"]

#---
x[!, Not(1)]

#---
x[!, Between(:x2, :x4)]

#---
x[!, Cols(:x1, Between(:x3, :x5))]

#---
select(x, :x1, Between(:x3, :x5), copycols=false) # the same as above

#   you can use `select` and `select!` functions to select a subset of columns from a data frame. `select` creates a new data frame and `select!` operates in place
df = copy(x)

#---
df2 = select(df, [1, 2])

#---
select(df, Not([1, 2]))

#   by default `select` copies columns
df2[!, 1] === df[!, 1]

#   this can be avoided by using `copycols=false` keyword argument
df2 = select(df, [1, 2], copycols=false)

#---
df2[!, 1] === df[!, 1]

#   using `select!` will modify the source data frame
select!(df, [1,2])

#---
df == df2

#   Here we create a copy of `x` and delete the 3rd column from the copy with `select!` and `Not`.
z = copy(x)
select!(z, Not(3))

#   alternatively we can achieve the same by using the `select` function
select(x, Not(3))

#   `x` stays unchanged

x

#   ## Views
#   Note, that you can also create a view of a DataFrame when we want a subset of its columns:
@btime x[:, [1,3,5]]

#---
@btime @view x[:, [1,3,5]]

#   (now creation of the `view` is slow, but in the coming releases of the `DataFrames.jl` package it will become significantly faster)

#  ## Modify column by name

x = DataFrame([(i,j) for i in 1:3, j in 1:5], :auto)

#   With the following syntax, the existing column is modified without  performing any copying (this is discouraged as it creates column alias).

x[!, :x1] = x[!, :x2]
x

#   this syntax is safer
x[!, :x1] = x[:, :x2]

#   We can also use the following syntax to add a new column at the end of a `DataFrame`.

x[!, :A] = [1,2,3]
x

#   A new column name will be added to our `DataFrame` with the following syntax as well:

x.B = 11:13
x

#  ## Find column name
x = DataFrame([(i,j) for i in 1:3, j in 1:5], :auto)

#   We can check if a column with a given name exists via
hasproperty(x, :x1)

#   and determine its index via
columnindex(x, :x2)

#   ## Advanced ways of column selection
#   these are most useful for non-standard column names (e.g. containing spaces)

df = DataFrame()
df.x1 = 1:3
df[!, "column 2"] = 4:6
df

#---
df."column 2"

#---
df[:, "column 2"]

#   or you can interpolate column name using `:()` syntax

for n in names(df)
    println(n, "\n", df.:($n), "\n")
end

#   ## Working on a collection of columns
#   When using `eachcol` of a data frame the resulting object retains reference to its parent and e.g. can be queried with `getproperty`

df = DataFrame(reshape(1:12, 3, 4), :auto)

#---
ec_df = eachcol(df)

#---
ec_df[1]

#---
ec_df.x1

#===
## Transforming columns

We will get to this subject later in 10_transforms.ipynb notebook, but here let us just note that `select`, `select!`, `transform`, `transform!` and `combine` functions allow to generate new columns based on the old columns of a data frame.

The general rules are the following:
* `select` and `transform` always return the number of rows equal to the source data frame, while `combine` returns any number of rows (`combine` is allowed to *combine* rows of the source data frame)
* `transform` retains columns from the old data frame
* `select!` and `transform!` are in-place versions of `select` and `transform`
===#
df = DataFrame(reshape(1:12, 3, 4), :auto)

#===
Here we add a new column `:res` that is a sum of columns `:x1` and `:x2`. A general syntax of transformations of this kind is:

```
source_columns => function_to_apply => target_column_name
```
then `function_to_apply` gets columns selected by `source_columns` as positional arguments.
===#
transform(df, [:x1, :x2] => (+) => :res)

#   One can omit passing target_column_name in which case it is automatically generated:
using Statistics

#---
combine(df, [:x1, :x2] => cor)

#===
Note that `combine` allowed the number of columns in the resulting data frame to be changed. If we used `select` instead it would automatically broadcast the return value to match the number of rouws of the source:
===#
select(df, [:x1, :x2] => cor)

#  If you want to apply some function on each row of the source wrap it in  `ByRow`:
select(df, :x1, :x2, [:x1, :x2] => ByRow(string))

#  Also if you want columns to be passed as a `NamedTuple` to a funcion (instead of being positional arguments) wrap them in `AsTable`:
select(df, :x1, :x2, AsTable([:x1, :x2]) => x -> x.x1 + x.x2)

#   For simplicity (as this functionality is often needed) there is a special treatement of nrow function that can be just passed as a transformation (without specifying of column selector):
select(df, :x1, nrow => "number_of_rows")

# (note that in `select` the number of rows is automatically broadcasted to match the number of rows of the source data frame)

# Finally you can conveninently create multiple columns with one function, e.g.:
select(df, :x1, :x1 => ByRow(x -> [x ^ 2, x ^ 3]) => ["x1²", "x1³"])

# or e.g. (this produces the same result)
select(df, :x1, :x1 => (x -> DataFrame("x1²" => x .^ 2, "x1³" => x .^ 3)) => AsTable)

#   Note that since `DataFrames.jl` row aggregation for wide tables is efficient. Here is an example of a wide table with `sum` (other standard reductions are similarly supported):
large_df = DataFrame(rand(1000, 10000), :auto)

#---
@time select(large_df, AsTable(:) => ByRow(sum) => :sum)

#---
@time select(large_df, AsTable(:) => ByRow(sum) => :sum)
