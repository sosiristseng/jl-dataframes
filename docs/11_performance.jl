# # Performance tips
using DataFrames
using BenchmarkTools
using CategoricalArrays
using PooledArrays
using Random

# ## Access by column number is faster than by name

x = DataFrame(rand(5, 1000), :auto)
@btime $x[!, 500];
@btime $x.x500;

# ## When working with data DataFrame use barrier functions or type annotation

function f_bad() ## this function will be slow
    Random.seed!(1)
    x = DataFrame(rand(1000000, 2), :auto)
    y, z = x[!, 1], x[!, 2]
    p = 0.0
    for i in 1:nrow(x)
        p += y[i] * z[i]
    end
    p
end

@btime f_bad();
## if you run @code_warntype f_bad() then you notice
## that Julia does not know column types of `DataFrame`


# solution 1 is to use barrier function (it should be possible to use it in almost any code)
function f_inner(y, z)
    p = 0.0
    for i in 1:length(y)
        p += y[i] * z[i]
    end
    p
end

# extract the work to an inner function
function f_barrier()
    Random.seed!(1)
    x = DataFrame(rand(1000000, 2), :auto)
    f_inner(x[!, 1], x[!, 2])
end

# or use inbuilt function if possible
using LinearAlgebra
function f_inbuilt()
    Random.seed!(1)
    x = DataFrame(rand(1000000, 2), :auto)
    dot(x[!, 1], x[!, 2])
end

#---
@btime f_barrier();
@btime f_inbuilt();

# solution 2 is to provide the types of extracted columns. It is simpler but there are cases in which you will not know these types. This example  assumes that you have DataFrames master at least from August 31, 2018

function f_typed()
    Random.seed!(1)
    x = DataFrame(rand(1000000, 2), :auto)
    y::Vector{Float64}, z::Vector{Float64} = x[!, 1], x[!, 2]
    p = 0.0
    for i in 1:nrow(x)
        p += y[i] * z[i]
    end
    p
end

@btime f_typed();

#===
In general for tall and narrow tables it is often useful to use `Tables.rowtable`, `Tables.columntable` or `Tables.namedtupleiterator` for intermediate processing of data in a type-stable way.

## Consider using delayed `DataFrame` creation technique

also notice the difference in performance between copying vs non-copying data frame creation
===#

function f1()
    x = DataFrame([Vector{Float64}(undef, 10^4) for i in 1:100], :auto, copycols=false) ## we work with a DataFrame directly
    for c in 1:ncol(x)
        d = x[!, c]
        for r in 1:nrow(x)
            d[r] = rand()
        end
    end
    x
end

function f1a()
    x = DataFrame([Vector{Float64}(undef, 10^4) for i in 1:100], :auto) ## we work with a DataFrame directly
    for c in 1:ncol(x)
        d = x[!, c]
        for r in 1:nrow(x)
            d[r] = rand()
        end
    end
    x
end

function f2()
    x = Vector{Any}(undef, 100)
    for c in 1:length(x)
        d = Vector{Float64}(undef, 10^4)
        for r in 1:length(d)
            d[r] = rand()
        end
        x[c] = d
    end
    DataFrame(x, :auto, copycols=false) ## we delay creation of DataFrame after we have our job done
end

function f2a()
    x = Vector{Any}(undef, 100)
    for c in 1:length(x)
        d = Vector{Float64}(undef, 10^4)
        for r in 1:length(d)
            d[r] = rand()
        end
        x[c] = d
    end
    DataFrame(x, :auto) ## we delay creation of DataFrame after we have our job done
end

@btime f1();
@btime f1a();
@btime f2();
@btime f2a();

# ## You can add rows to a DataFrame in place and it is fast

x = DataFrame(rand(10^6, 5), :auto)
y = DataFrame(transpose(1.0:5.0), :auto)
z = [1.0:5.0;]

@btime vcat($x, $y); ## creates a new DataFrame - slow
@btime append!($x, $y); ## in place - fast

x = DataFrame(rand(10^6, 5), :auto) ## reset to the same starting point
@btime push!($x, $z); ## add a single row in place - fast

# ## Allowing missing as well as categorical slows down computations
using StatsBase

function test(data) ## uses countmap function to test performance
    println(eltype(data))
    x = rand(data, 10^6)
    y = categorical(x)
    println(" raw:")
    @btime countmap($x)
    println(" categorical:")
    @btime countmap($y)
    nothing
end

test(1:10)
test([randstring() for i in 1:10])
test(allowmissing(1:10))
test(allowmissing([randstring() for i in 1:10]))

# ## When aggregating use column selector and prefer integer, categorical, or pooled array grouping variable
df = DataFrame(x=rand('a':'d', 10^7), y=1);

#---
gdf = groupby(df, :x)

# traditional syntax, slow
@btime combine(v -> sum(v.y), $gdf)

# use column selector
@btime combine($gdf, :y => sum)

#---
transform!(df, :x => categorical => :x);
gdf = groupby(df, :x)

#---
@btime combine($gdf, :y => sum)

#---
transform!(df, :x => PooledArray{Char} => :x)

#---
gdf = groupby(df, :x)

#---
@btime combine($gdf, :y => sum)

# ## Use views instead of materializing a new DataFrame
x = DataFrame(rand(100, 1000), :auto)

#---
@btime $x[1:1, :]

#---
@btime $x[1, :]

#---
@btime view($x, 1:1, :)

#---
@btime $x[1:1, 1:20]

#---
@btime $x[1, 1:20]

#---
@btime view($x, 1:1, 1:20)
