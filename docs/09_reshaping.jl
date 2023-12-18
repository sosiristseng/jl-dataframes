#  # Reshaping DataFrames
using DataFrames

# ## Wide to long
x = DataFrame(id=[1, 2, 3, 4], id2=[1, 1, 2, 2], M1=[11, 12, 13, 14], M2=[111, 112, 113, 114])

# first pass measure variables and then id-variable
stack(x, [:M1, :M2], :id)

# add `view=true` keyword argument to make a view; in that case columns of the resulting data frame share memory with columns of the source data frame, so the operation is potentially unsafe
# optionally you can rename columns
stack(x, ["M1", "M2"], "id", variable_name="key", value_name="observed")

#   if second argument is omitted in `stack` , all other columns are assumed to be the id-variables

stack(x, Not([:id, :id2]))

# you can use index instead of symbol
stack(x, Not([1, 2]))

#---
x = DataFrame(id=[1, 1, 1], id2=['a', 'b', 'c'], a1=rand(3), a2=rand(3))

# if `stack` is not passed any measure variables by default numeric variables are selected as measures
stack(x)

# here all columns are treated as measures:
stack(DataFrame(rand(3, 2), :auto))

#---
df = DataFrame(rand(3, 2), :auto)
df.key = [1, 1, 1]
mdf = stack(df) ## duplicates in key are silently accepted

# ## Long to wide
x = DataFrame(id=[1, 1, 1], id2=['a', 'b', 'c'], a1=rand(3), a2=rand(3))

#---
y = stack(x)

# stndard unstack with a specified key
unstack(y, :id2, :variable, :value)

# all other columns are treated as keys
unstack(y, :variable, :value)

# all columns other than named :variable and :value are treated as keys
unstack(y)

# you can rename the unstacked columns
unstack(y, renamecols=n -> string("unstacked_", n))

#---
df = stack(DataFrame(rand(3, 2), :auto))

# unable to unstack when no key column is present
try
    unstack(df, :variable, :value)
catch e
    show(e)
end

# `unstack` fills missing combinations with `missing`, but you can change this default with `fill` keyword argument.
df = DataFrame(key=[1, 1, 2], variable=["a", "b", "a"], value=1:3)

#---
unstack(df, :variable, :value)

#---
unstack(df, :variable, :value, fill=0)
