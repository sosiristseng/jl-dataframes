#===
# Manipulating columns of a `DataFrame`
## Renaming columns

Let's start with a `DataFrame` of `Bool`s that has default column names.
===#
using DataFrames

#---
x = DataFrame(rand(Bool, 3, 4), :auto)

# With `rename`, we create new `DataFrame`; here we rename the column `:x1` to `:A`. (`rename` also accepts collections of Pairs.)
rename(x, :x1 => :A)

# With `rename!` we do an in place transformation.
# This time we've applied a function to every column name (note that the function gets a column names as a string).
rename!(c -> c^2, x)

# We can also change the name of a particular column without knowing the original.
# Here we change the name of the third column, creating a new `DataFrame`.
rename(x, 3 => :third)

# If we pass a vector of names to `rename!`, we can change the names of all variables.
rename!(x, [:a, :b, :c, :d])

# In all the above examples you could have used strings instead of symbols, e.g.
rename!(x, string.('a':'d'))
