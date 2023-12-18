# # Joining DataFrames
using DataFrames

# ## Preparing DataFrames for a join
x = DataFrame(ID=[1, 2, 3, 4, missing], name=["Alice", "Bob", "Conor", "Dave", "Zed"])

#---
y = DataFrame(id=[1, 2, 5, 6, missing], age=[21, 22, 23, 24, 99])

#===
Rules for the `on` keyword argument:
* a single `Symbol` or string if joining on one column with the same name, e.g. `on=:id`
* a `Pair` of `Symbol`s or string if joining on one column with different names, e.g. `on=:id=>:id2`
* a vector of `Symbol`s or strings if joining on multiple columns with the same name, e.g. `on=[:id1, :id2]`
* a vector of `Pair`s of `Symbol`s or strings if joining on multiple columns with different names, e.g. `on=[:a1=>:a2, :b1=>:b2]`
* a vector containing a combination of `Symbol`s or strings or `Pair` of `Symbol`s or strings, e.g. `on=[:a1=>:a2, :b1]`
===#

try
    innerjoin(x, y, on=:ID => :id) ## missing is not allowed to join-on by default
catch e
    show(e)
end

#---
innerjoin(x, y, on=:ID => :id, matchmissing=:equal)

#---
leftjoin(x, y, on="ID" => "id", matchmissing=:equal)

#---
rightjoin(x, y, on=:ID => :id, matchmissing=:equal)

#---
outerjoin(x, y, on=:ID => :id, matchmissing=:equal)

#---
semijoin(x, y, on=:ID => :id, matchmissing=:equal)

#---
antijoin(x, y, on=:ID => :id, matchmissing=:equal)

# ## Cross join
#  (here no `on` argument)

crossjoin(DataFrame(x=[1, 2]), DataFrame(y=["a", "b", "c"]))

# ## Complex cases of joins
x = DataFrame(id1=[1, 1, 2, 2, missing, missing],
    id2=[1, 11, 2, 21, missing, 99],
    name=["Alice", "Bob", "Conor", "Dave", "Zed", "Zoe"])

#---
y = DataFrame(id1=[1, 1, 3, 3, missing, missing],
    id2=[11, 1, 31, 3, missing, 999],
    age=[21, 22, 23, 24, 99, 100])

# joining on two columns
innerjoin(x, y, on=[:id1, :id2], matchmissing=:equal)

# with duplicates all combinations are produced
outerjoin(x, y, on=:id1, makeunique=true, indicator=:source, matchmissing=:equal)

# you can force validation of uniqueness of key on which you join
try
    innerjoin(x, y, on=:id1, makeunique=true, validate=(true, true), matchmissing=:equal)
catch e
    show(e)
end

#  mixed `on` argument for joining on multiple columns
x = DataFrame(id1=1:6, id2=[1, 2, 1, 2, 1, 2], x1='a':'f')

#---
y = DataFrame(id1=1:6, ID2=1:6, x2='a':'f')

#---
innerjoin(x, y, on=[:id1, :id2 => :ID2])

# joining more than two data frames
xs = [DataFrame("id" => 1:6, "v$i" => ((1:6) .+ 10i)) for i in 1:5]

# innerjoin as an example, it also works for outerjoin and crossjoin
innerjoin(xs..., on=:id)

#===
## matchmissing keyword argument
In general you have three options how `missing` values are handled in joins that are handled by `matchmisssing` kewyowrd argument value as follows:
* `:error`: throw an error if missings are encountered (this is the default)
* `:equal`: assume `misssing` values are equal to themselves
* `:notequal`: assume `misssing` values are not equal to themselves (not available for `outerjoin`)

Here are some examples comparing the options:
===#

df1 = DataFrame(id=[1, 2, missing], x=1:3)

#---
df2 = DataFrame(id=[1, missing, 3], y=1:3)

#---
try
    innerjoin(df1, df2, on=:id)
catch e
    show(e)
end

#---
innerjoin(df1, df2, on=:id, matchmissing=:equal)

#---
innerjoin(df1, df2, on=:id, matchmissing=:notequal)

# Since DataFrames.jl 1.3 you can do an efficient left join of two data frames in-place. This means that the left data frame gets updated with new columns, but the columns that exist in it are not affected. This operation requires that there are no duplicates of keys in the right data frame that match keys in left data frame:

df1

#---
df2

#---
leftjoin!(df1, df2, on=:id, matchmissing=:notequal)

#---
df1
