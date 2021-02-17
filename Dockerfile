FROM condaforge/miniforge3

RUN conda update -y --all \
    && conda install conda-build conda-verify

COPY environment.yml .
RUN conda env create -f environment.yml

SHELL ["/bin/bash", "-c"]

RUN . /opt/conda/etc/profile.d/conda.sh \
    && conda activate anguilla-devcontainer
