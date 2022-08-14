FROM python:3.10-slim

WORKDIR /usr/src/app

ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Julia
ENV JULIA_PATH /usr/local/julia/
ENV PATH $JULIA_PATH/bin:$PATH
COPY --from=julia:1.7.3 ${JULIA_PATH} /usr/local/

# System packages
RUN apt-get update && apt-get install -y git parallel --no-install-recommends && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -U pip wheel setuptools \
    && pip install --no-cache-dir -r requirements.txt

# Julia environment
COPY Project.toml Manifest.toml ./
# COPY src/ src # If you have this
RUN julia --threads=auto --color=yes --project=@. -e 'import Pkg; Pkg.instantiate()'

CMD ["julia"]