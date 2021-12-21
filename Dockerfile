FROM intel/oneapi-hpckit

RUN apt-get update && apt-get install -y wget emacs-nox make tar zlib1g-dev curl libssl-dev sudo git m4 libncurses5-dev libncursesw5-dev libgsl-dev

# Add a default non-root user to run mpi jobs
ARG USER=user
ENV USER ${USER}
RUN adduser ${USER} && echo "${USER}   ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

ENV USER_HOME /home/${USER}
RUN chown -R ${USER}:${USER} ${USER_HOME}
RUN mkdir /software
RUN chown -R ${USER}:${USER} /software

# Create working directory
ARG WORKDIR=/workspace
ENV WORKDIR ${WORKDIR}
RUN mkdir ${WORKDIR}
RUN chown -R ${USER}:${USER} ${WORKDIR}

WORKDIR ${WORKDIR}
USER ${USER}


# Install miniconda 
RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && bash ~/miniconda.sh -b -p /software/miniconda/
RUN echo 'eval "$(/software/miniconda/bin/conda shell.bash hook)"' >> ~/.bashrc
# Do this later with spack 

# Install cmake 
RUN wget https://github.com/Kitware/CMake/releases/download/v3.18.1/cmake-3.18.1-Linux-x86_64.tar.gz && tar -xvzf cmake-3.18.1-Linux-x86_64.tar.gz && mv cmake-3.18.1-Linux-x86_64 /software/cmake



# install spack
ENV SPACK_ROOT=/software/spack
RUN mkdir $SPACK_ROOT && curl -s -L https://api.github.com/repos/llnl/spack/tarball | tar xzC $SPACK_ROOT --strip 1
RUN echo ". $SPACK_ROOT/share/spack/setup-env.sh" >> ${USER_HOME}/.bashrc

ENV PATH="$SPACK_ROOT/bin:${PATH}"
RUN mkdir -p ${USER_HOME}/.spack
COPY packages.yaml ${USER_HOME}/.spack/packages.yaml

RUN sudo apt-get install -y cpio autoconf automake perl 
# install hdf5, CGNS and NetCDF 
RUN spack install cgns+mpi+fortran%intel^hdf5+mpi+hl+fortran+cxx%intel^intel-mpi
RUN spack install netcdf-fortran+mpi%intel^hdf5%intel+cxx~debug+fortran+hl~java+mpi+pic+shared~szip~threadsafe^intel-mpi

# Install pFUnit 
RUN eval `spack load --sh hdf5` && eval `spack load --sh cmake` && echo $(which cmake) && wget https://github.com/Goddard-Fortran-Ecosystem/pFUnit/releases/download/v4.1.7/pFUnit.tar && tar -xvf pFUnit.tar && cd pFUnit-4.1.7 && mkdir build && cd build && export CC=mpiicc && export FC=mpiifort && cmake .. -DCMAKE_C_COMPILER=${CC} -DCMAKE_Fortran_COMPILER=${FC} -DCMAKE_INSTALL_PREFIX=/software/ && make -j && make -j install

COPY requirements.txt ${WORKDIR}/requirements.txt 
RUN eval "$(/software/miniconda/bin/conda shell.bash hook)" && conda install -y h5py && conda install -y -c conda-forge cartopy netcdf4 && pip install PyQt5 f90nml ipykernel --upgrade && pip install -r ${WORKDIR}/requirements.txt 
