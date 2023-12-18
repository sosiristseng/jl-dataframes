#===
# Julia DataFrames Examples

A brief introduction to basic usage of [DataFrames](https://github.com/JuliaData/DataFrames.jl), by [Bogumił Kamiński](http://bogumilkaminski.pl/about/) in <https://github.com/bkamins/Julia-DataFrames-Tutorial/>, *December 12, 2021*.

The tutorial contains a specification of the project environment version under
which it should be run. In order to prepare this environment, before using the
tutorial notebooks, while in the project folder run the following command in the
command line:

```sh
julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'
```
===#

# ## Runtime information

using InteractiveUtils
versioninfo()

#---
using Pkg
Pkg.status()
