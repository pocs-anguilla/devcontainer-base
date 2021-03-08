# Adapted from: https://git.io/JqIAN
FROM ubuntu:hirsute

ARG MINIFORGE_VERSION=4.9.2-7
ARG TINI_VERSION=v0.19.0

ENV CONDA_DIR=/opt/mamba
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=${CONDA_DIR}/bin:${PATH}

# Install just enough for conda to work
RUN apt-get update > /dev/null && \
    apt-get install -y --no-install-recommends \
        wget bzip2 ca-certificates apt-transport-https gnupg2 software-properties-common git \
    > /dev/null && \
    (wget https://apt.llvm.org/llvm-snapshot.gpg.key -O - | apt-key add -) && \
    deb https://apt.llvm.org/hirsute/ llvm-toolchain-hirsute-12 main && \
    deb-src https://apt.llvm.org/hirsute/ llvm-toolchain-hirsute-12 main && \
    apt-get install --no-install-recommends --yes \
        libllvm12 llvm-12 llvm-12-dev llvm-12-runtime \
        clang-12 clang-tools-12 libclang-common-12-dev libclang-12-dev libclang1-12 \
        clang-format-12 python-clang-12 clangd-12 \
        lld-12 libc++-12-dev libc++abi-12-dev libomp-12-dev \
    > /dev/null && \
    apt-get remove -y apt-transport-https gnupg2 software-properties-common && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Keep $HOME clean (no .wget-hsts file), since HSTS isn't useful in this context
RUN wget --no-hsts --quiet https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini -O /usr/local/bin/tini && \
    chmod +x /usr/local/bin/tini

# 1. Install Mambaforge from GitHub releases
# 2. Apply some cleanup tips from https://jcrist.github.io/conda-docker-tips.html
#    Particularly, we remove pyc and a files. The default install has no js, we can skip that
RUN wget --no-hsts --quiet https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Mambaforge3-${MINIFORGE_VERSION}-Linux-x86_64.sh -O /tmp/mambaforge.sh && \
    /bin/bash /tmp/mambaforge.sh -b -p ${CONDA_DIR} && \
    rm /tmp/mambaforge.sh && \
    mamba clean -tipsy && \
    mamba update -y --all && \
    mamba install conda-build conda-verify && \
    find ${CONDA_DIR} -follow -type f -name '*.a' -delete && \
    find ${CONDA_DIR} -follow -type f -name '*.pyc' -delete && \
    mamba clean -afy

# Activate base by default when running as any *non-root* user as well
# Good security practice requires running most workloads as non-root
# This makes sure any non-root users created also have base activated
# for their interactive shells.
RUN echo ". ${CONDA_DIR}/etc/profile.d/mamba.sh && mamba activate anguilla-devcontainer" >> /etc/skel/.bashrc

# Activate base by default when running as root as well
# The root user is already created, so won't pick up changes to /etc/skel
RUN echo ". ${CONDA_DIR}/etc/profile.d/mamba.sh && mamba activate anguilla-devcontainer" >> ~/.bashrc

ENTRYPOINT ["tini", "--"]
CMD [ "/bin/bash" "-c"]

COPY environment.yml .
RUN . ${CONDA_DIR}/etc/profile.d/mamba.sh && mamba activate base && \
    mamba env create -f environment.yml