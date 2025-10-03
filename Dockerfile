# Usa un'immagine di base leggera e stabile
FROM debian:bullseye-slim

# Imposta variabili per rendere il file più leggibile e manutenibile
ARG JULIA_VERSION=1.10.0
# ---> MODIFICA: Aggiungiamo il percorso locale dell'utente al PATH <---
ENV JULIA_DEPOT_PATH="/home/jovyan/.julia" \
    PATH="/home/jovyan/.local/bin:/usr/local/julia/bin:${PATH}"

# Installa i pacchetti di sistema necessari
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    wget \
    ca-certificates \
    python3 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Scarica, verifica e installa Julia
RUN mkdir /usr/local/julia \
    && cd /usr/local/julia \
    && wget -q "https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VERSION%[.-]*}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz" \
    && tar -xzf "julia-${JULIA_VERSION}-linux-x86_64.tar.gz" -C . --strip-components=1 \
    && rm "julia-${JULIA_VERSION}-linux-x86_64.tar.gz" \
    && ln -fs /usr/local/julia/bin/julia /usr/local/bin/julia

# Crea un utente non-root chiamato 'jovyan' (standard per Jupyter) per evitare problemi di permessi
RUN useradd -m -s /bin/bash -N -u 1000 jovyan
USER jovyan
WORKDIR /home/jovyan/work

# Dice esplicitamente a PyCall quale Python usare
ENV PYTHON=python3

# Installa le librerie Python necessarie
COPY python_requirements.txt .
RUN pip install --no-cache-dir -r python_requirements.txt

# Installa IJulia e tutte le librerie Julia del corso
RUN julia -e 'using Pkg; \
    Pkg.add("IJulia"); \
    Pkg.add([ \
        "CSV", "DataFrames", "DecisionTree", "DelimitedFiles", "FileIO", "Flux", \
        "Images", "JLD2", "LIBSVM", "MAT", "MLJ", "MLJLinearModels", \
        "MultivariateStats", "NaiveBayes", "NearestNeighborModels", "Plots", \
        "Pluto", "ScikitLearn", "Statistics", "StatsPlots", "TSne", "Tables", "XLSX" \
    ]); \
    Pkg.precompile();'

# Esponi la porta di Jupyter e imposta il comando di avvio
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--NotebookApp.token=''"]