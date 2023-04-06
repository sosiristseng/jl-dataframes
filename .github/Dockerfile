FROM FROM ghcr.io/sosiristseng/docker-jupyterbook:0.15.1.2 as base

FROM base

WORKDIR /app

# Julia environment
COPY Project.toml Manifest.toml ./
COPY src/ src
RUN julia --color=yes --project="" -e 'import Pkg; Pkg.add("IJulia"); using IJulia; installkernel("Julia", "--project=@.")' && \
    julia --color=yes --project=@. -e 'import Pkg; Pkg.instantiate(); Pkg.resolve(); Pkg.precompile()' 
    
CMD ["jupyter", "nbconvert"]
