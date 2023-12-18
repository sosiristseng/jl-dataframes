#===
# Load and save DataFrames

We do not cover all features of the packages. Please refer to their documentation to learn them.

- https://github.com/ExpandingMan/Arrow.jl
- https://github.com/invenia/JLSO.jl
- https://github.com/JuliaData/JSONTables.jl
- https://github.com/xiaodaigh/JDF.jl

Here we'll load `CSV.jl` to read and write CSV files and `Arrow.jl`, `JLSO.jl`, and serialization, which allow us to work with a binary format and `JSONTables.jl` for JSON interaction. Finally we consider a custom `JDF.jl` format.
===#

using DataFrames
using Arrow
using CSV
using Serialization
using JLSO
using JSONTables
using CodecZlib
using ZipFile
using JDF
using StatsPlots ## for charts
using Mmap ## for compression

# Let's create a simple `DataFrame` for testing purposes,
x = DataFrame(
    A=[true, false, true], B=[1, 2, missing],
    C=[missing, "b", "c"], D=['a', missing, 'c']
)

# and use `eltypes` to look at the columnwise types.
eltype.(eachcol(x))

# ## CSV.jl
# Let's use `CSV` to save `x` to disk; make sure `x1.csv` does not conflict with some file in your working directory.

CSV.write("x1.csv", x)

# Now we can see how it was saved by reading `x.csv`.
print(read("x1.csv", String))

# We can also load it back.
y = CSV.read("x1.csv", DataFrame)

# Note that when loading in a `DataFrame` from a `CSV` the column type for columns `:C` `:D` have changed to use special strings defined in the InlineStrings.jl package.
eltype.(eachcol(y))

#===
## Serialization by JDF.jl and JLSO.jl

Now we use serialization to save `x`.

There are two ways to perform serialization. The first way is to use the `Serialization.serialize` as below:

Note that in general, this process _will not work_ if the reading and writing are done by different versions of Julia, or an instance of Julia with a different system image.
===#

open("x.bin", "w") do io
    serialize(io, x)
end

# Now we load back the saved file to `y` variable. Again `y` is identical to `x`. However, please beware that if you session does not have DataFrames.jl loaded, then it may not recognise the content as DataFrames.jl

y = open(deserialize, "x.bin")

#---
eltype.(eachcol(y))

#===
### JDF.jl

`JDF.jl` is a relatively new package designed to serialize DataFrames. You can save a DataFrame with the `savejdf` function.

For more details about design assumptions and limitations of `JDF.jl` please check out https://github.com/xiaodaigh/JDF.jl.
===#

JDF.save("x.jdf", x);

# To load the saved JDF file, one can use the `loadjdf` function
x_loaded = JDF.load("x.jdf") |> DataFrame

# You can see that they are the same
isequal(x_loaded, x)

# JDF.jl offers the ability to load only certain columns from disk to help with working with large files

## set up a JDFFile which is a on disk representation of `x` backed by JDF.jl
x_ondisk = jdf"x.jdf"

# We can see all the names of `x` without loading it into memory
names(x_ondisk)

# The below is an example of how to load only columns `:A` and `:D`
xd = JDF.load(x_ondisk; cols=["A", "D"]) |> DataFrame

# ### JLSO.jl
# Another way to perform serialization is by using the [JLSO.jl](https://github.com/invenia/JLSO.jl) library:

JLSO.save("x.jlso", :data => x)

# Now we can load back the file to `y`
y = JLSO.load("x.jlso")[:data]

#---
eltype.(eachcol(y))

# ## JSONTables.jl
# Often you might need to read and write data stored in JSON format. JSONTables.jl provides a way to process them in row-oriented or column-oriented layout. We present both options below.

open(io -> arraytable(io, x), "x1.json", "w")

#---
open(io -> objecttable(io, x), "x2.json", "w")

#---
print(read("x1.json", String))

#---
print(read("x2.json", String))

#---
y1 = open(jsontable, "x1.json") |> DataFrame

#---
eltype.(eachcol(y1))

#---
y2 = open(jsontable, "x2.json") |> DataFrame

#---
eltype.(eachcol(y2))

# ## Arrow.jl
# Finally we use Apache Arrow format that allows, in particular, for data interchange with R or Python.
Arrow.write("x.arrow", x)

#---
y = Arrow.Table("x.arrow") |> DataFrame

#---
eltype.(eachcol(y))

# Note that columns of `y` are immutable
try
    y.A[1] = false
catch e
    show(e)
end

# This is because `Arrow.Table` uses memory mapping and thus uses a custom vector types:
y.A

#---
y.B

# You can get standard Julia Base vectors by copying a data frame
y2 = copy(y)

#---
y2.A

#---
y2.B

#===
## Basic bechmarking

Next, we'll create some files, so be careful that you don't already have these files in your working directory!

In particular, we'll time how long it takes us to write a `DataFrame` with 1000 rows and 100000 columns.
===#

bigdf = DataFrame(rand(Bool, 10^4, 1000), :auto)

bigdf[!, 1] = Int.(bigdf[!, 1])
bigdf[!, 2] = bigdf[!, 2] .+ 0.5
bigdf[!, 3] = string.(bigdf[!, 3], ", as string")

println("First run")

#---
println("CSV.jl")
csvwrite1 = @elapsed @time CSV.write("bigdf1.csv", bigdf)
println("Serialization")
serializewrite1 = @elapsed @time open(io -> serialize(io, bigdf), "bigdf.bin", "w")
println("JDF.jl")
jdfwrite1 = @elapsed @time JDF.save("bigdf.jdf", bigdf)
println("JLSO.jl")
jlsowrite1 = @elapsed @time JLSO.save("bigdf.jlso", :data => bigdf)
println("Arrow.jl")
arrowwrite1 = @elapsed @time Arrow.write("bigdf.arrow", bigdf)
println("JSONTables.jl arraytable")
jsontablesawrite1 = @elapsed @time open(io -> arraytable(io, bigdf), "bigdf1.json", "w")
println("JSONTables.jl objecttable")
jsontablesowrite1 = @elapsed @time open(io -> objecttable(io, bigdf), "bigdf2.json", "w")
println("Second run")
println("CSV.jl")
csvwrite2 = @elapsed @time CSV.write("bigdf1.csv", bigdf)
println("Serialization")
serializewrite2 = @elapsed @time open(io -> serialize(io, bigdf), "bigdf.bin", "w")
println("JDF.jl")
jdfwrite2 = @elapsed @time JDF.save("bigdf.jdf", bigdf)
println("JLSO.jl")
jlsowrite2 = @elapsed @time JLSO.save("bigdf.jlso", :data => bigdf)
println("Arrow.jl")
arrowwrite2 = @elapsed @time Arrow.write("bigdf.arrow", bigdf)
println("JSONTables.jl arraytable")
jsontablesawrite2 = @elapsed @time open(io -> arraytable(io, bigdf), "bigdf1.json", "w")
println("JSONTables.jl objecttable")
jsontablesowrite2 = @elapsed @time open(io -> objecttable(io, bigdf), "bigdf2.json", "w")

# Exclude JSONTables.jl arraytable due to timing
groupedbar(
    repeat(["CSV.jl", "Serialization", "JDF.jl", "JLSO.jl", "Arrow.jl", "JSONTables.jl\nobjecttable"],
        inner=2),
    [csvwrite1, csvwrite2, serializewrite1, serializewrite1, jdfwrite1, jdfwrite2,
        jlsowrite1, jlsowrite2, arrowwrite1, arrowwrite2, jsontablesowrite2, jsontablesowrite2],
    group=repeat(["1st", "2nd"], outer=6),
    ylab="Second",
    title="Write Performance\nDataFrame: bigdf\nSize: $(size(bigdf))"
)

#---
data_files = ["bigdf1.csv", "bigdf.bin", "bigdf.arrow", "bigdf1.json", "bigdf2.json"]
df = DataFrame(file=data_files, size=getfield.(stat.(data_files), :size))
append!(df, DataFrame(file="bigdf.jdf", size=reduce((x, y) -> x + y.size,
    stat.(joinpath.("bigdf.jdf", readdir("bigdf.jdf"))),
    init=0)))
sort!(df, :size)

#---
@df df plot(:file, :size / 1024^2, seriestype=:bar, title="Format File Size (MB)", label="Size", ylab="MB")

#---
println("First run")
println("CSV.jl")
csvread1 = @elapsed @time CSV.read("bigdf1.csv", DataFrame)
println("Serialization")
serializeread1 = @elapsed @time open(deserialize, "bigdf.bin")
println("JDF.jl")
jdfread1 = @elapsed @time JDF.load("bigdf.jdf") |> DataFrame
println("JLSO.jl")
jlsoread1 = @elapsed @time JLSO.load("bigdf.jlso")
println("Arrow.jl")
arrowread1 = @elapsed @time df_tmp = Arrow.Table("bigdf.arrow") |> DataFrame
arrowread1copy = @elapsed @time copy(df_tmp)
println("JSONTables.jl arraytable")
jsontablesaread1 = @elapsed @time open(jsontable, "bigdf1.json")
println("JSONTables.jl objecttable")
jsontablesoread1 = @elapsed @time open(jsontable, "bigdf2.json")
println("Second run")
csvread2 = @elapsed @time CSV.read("bigdf1.csv", DataFrame)
println("Serialization")
serializeread2 = @elapsed @time open(deserialize, "bigdf.bin")
println("JDF.jl")
jdfread2 = @elapsed @time JDF.load("bigdf.jdf") |> DataFrame
println("JLSO.jl")
jlsoread2 = @elapsed @time JLSO.load("bigdf.jlso")
println("Arrow.jl")
arrowread2 = @elapsed @time df_tmp = Arrow.Table("bigdf.arrow") |> DataFrame
arrowread2copy = @elapsed @time copy(df_tmp)
println("JSONTables.jl arraytable")
jsontablesaread2 = @elapsed @time open(jsontable, "bigdf1.json")
println("JSONTables.jl objecttable")
jsontablesoread2 = @elapsed @time open(jsontable, "bigdf2.json");

# Exclude JSON arraytable due to much longer timing
groupedbar(
    repeat(["CSV.jl", "Serialization", "JDF.jl", "JLSO.jl", "Arrow.jl", "Arrow.jl\ncopy", #"JSON\narraytable",
            "JSON\nobjecttable"], inner=2),
    [csvread1, csvread2, serializeread1, serializeread2, jdfread1, jdfread2, jlsoread1, jlsoread2,
        arrowread1, arrowread2, arrowread1 + arrowread1copy, arrowread2 + arrowread2copy,
        ## jsontablesaread1, jsontablesaread2,
        jsontablesoread1, jsontablesoread2],
    group=repeat(["1st", "2nd"], outer=7),
    ylab="Second",
    title="Read Performance\nDataFrame: bigdf\nSize: $(size(bigdf))"
)

#===
## Using gzip compression
A common user requirement is to be able to load and save CSV that are compressed using gzip. Below we show how this can be accomplished using `CodecZlib.jl`. The same pattern is applicable to `JSONTables.jl` compression/decompression.

Again make sure that you do not have file named `df_compress_test.csv.gz` in your working directory.

We first generate a random data frame.
===#

df = DataFrame(rand(1:10, 10, 1000), :auto)

#---

## GzipCompressorStream comes from CodecZlib
open("df_compress_test.csv.gz", "w") do io
    stream = GzipCompressorStream(io)
    CSV.write(stream, df)
    close(stream)
end

#---
df2 = CSV.File(transcode(GzipDecompressor, Mmap.mmap("df_compress_test.csv.gz"))) |> DataFrame

#---
df == df2

#===
## Using zip files

Sometimes you may have files compressed inside a zip file.

In such a situation you may use [ZipFile.jl](https://github.com/fhs/ZipFile.jl) in conjunction an an appropriate reader to read the files.

Here we first create a ZIP file and then read back its contents into a `DataFrame`.
===#
df1 = DataFrame(rand(1:10, 3, 4), :auto)

#---
df2 = DataFrame(rand(1:10, 3, 4), :auto)

# And we show yet another way to write a `DataFrame` into a CSV file:
# writing a CSV file into the zip file
w = ZipFile.Writer("x.zip")

f1 = ZipFile.addfile(w, "x1.csv")
write(f1, sprint(show, "text/csv", df1))

## write a second CSV file into zip file
f2 = ZipFile.addfile(w, "x2.csv", method=ZipFile.Deflate)
write(f2, sprint(show, "text/csv", df2))

close(w)

# Now we read the CSV we have written:
z = ZipFile.Reader("x.zip");

#---
## find the index index of file called x1.csv
index_xcsv = findfirst(x -> x.name == "x1.csv", z.files)
## to read the x1.csv file in the zip file
df1_2 = CSV.read(read(z.files[index_xcsv]), DataFrame)

#---
df1_2 == df1

#---
## find the index index of file called x2.csv
index_xcsv = findfirst(x -> x.name == "x2.csv", z.files)
## to read the x2.csv file in the zip file
df2_2 = CSV.read(read(z.files[index_xcsv]), DataFrame)

#---
df2_2 == df2

#===
Note that once you read a given file from `z` object its stream is all used-up (it is at its end). Therefore to read it again you need to close `z` and open it again.

Also do not forget to close the zip file once done.
===#
close(z)
