# # Possible pitfalls
using DataFrames

# ## Know what is copied when creating a DataFrame
x = DataFrame(rand(3, 5), :auto)

# x and y are not the same object
y = copy(x)
x === y

# x and y are not the same object
y = DataFrame(x)
x === y

# the columns are also not the same
any(x[!, i] === y[!, i] for i in ncol(x))

# x and y are not the same object
y = DataFrame(x, copycols=false)
x === y

# But the columns are the same
all(x[!, i] === y[!, i] for i in ncol(x))

# the same when creating data frames using kwarg syntax
x = 1:3;
y = [1, 2, 3];
df = DataFrame(x=x, y=y);

# different object
y === df.y

# range is converted to a vector
typeof(x), typeof(df.x)

# slicing rows always creates a copy
y === df[:, :y]

# you can avoid copying by using copycols=false keyword argument in functions.
df = DataFrame(x=x, y=y, copycols=false)

# now it is the same
y === df.y

# not the same
select(df, :y)[!, 1] === y

# the same
select(df, :y, copycols=false)[!, 1] === y

# ## Do not modify the parent of `GroupedDataFrame` or view
x = DataFrame(id=repeat([1, 2], outer=3), x=1:6)
g = groupby(x, :id)

x[1:3, 1] = [2, 2, 2]
g ## well - it is wrong now, g is only a view

#---
s = view(x, 5:6, :)

#---
delete!(x, 3:6)

#===
This is an error

```julia
s ## Will return BoundsError
```
===#

# ## Single column selection for `DataFrame` creates aliases with ! and `getproperty` syntax and copies with :

x = DataFrame(a=1:3)
x.b = x[!, 1] ## alias
x.c = x[:, 1] ## copy
x.d = x[!, 1][:] ## copy
x.e = copy(x[!, 1]) ## explicit copy
display(x)

#---
x[1, 1] = 100
display(x)

#===
## When iterating rows of a data frame

- use `eachrow` to avoid compilation cost (wide tables),
- but `Tables.namedtupleiterator` for fast execution (tall tables)

this table is wide
===#
df1 = DataFrame([rand([1:2, 'a':'b', false:true, 1.0:2.0]) for i in 1:900], :auto)

#---
@time collect(eachrow(df1))

#---
@time collect(Tables.namedtupleiterator(df1));

#===
as you can see the time to compile `Tables.namedtupleiterator` is very large in this case, and it would get much worse if the table was wider (that is why we include this tip in pitfalls notebook)

the table below is tall
===#

df2 = DataFrame(rand(10^6, 10), :auto)

#---
@time map(sum, eachrow(df2))

#---
@time map(sum, eachrow(df2))

#---
@time map(sum, Tables.namedtupleiterator(df2))

#---
@time map(sum, Tables.namedtupleiterator(df2))

#===
as you can see - this time it is much faster to iterate a type stable container

still you might want to use the `select` syntax, which is optimized for such reductions:
===#

# this includes compilation time
@time select(df2, AsTable(:) => ByRow(sum) => "sum").sum

# Do it again
@time select(df2, AsTable(:) => ByRow(sum) => "sum").sum
