FROM centos:7 as intermediate
RUN yum update -y && \
    yum install -y bash \
    git

ARG GH_USER
ARG GH_TOKEN

RUN git clone -b u/heather999/issue_13 https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-env.git && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-ei.git && \
    mv nexo-ei ExternalInterface && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/SNiPER-Framework/sniper.git

FROM centos:7 as runtime
MAINTAINER Heather Kelly <heather@slac.stanford.edu>

ENV NEXOTOP /opt/nexo/software

RUN yum update -y && \
    yum install -y bash \
    bison \
    blas \
    bzip2-devel \
    bzip2 \
    cmake \
    curl \
    flex \
    fontconfig \
    freetype-devel \
    gcc-c++ \
    gcc-gfortran \
    gettext \
    git \
    git-lsf \
    glibc \
    glibc-devel \
    glib2.0-devel \
    libuuid-devel \
    libselinux \
    libX11-devel \
    libXext \
    libXft-devel \
    libXpm-devel \
    libXrender \
    libXt-devel \
    make \
    mesa-libGLU \
    mesa-libGLU-devel \
    motif \
    motif-devel \
    ncurses-devel \
    openssl-devel \
    patch \
    perl \
    perl-ExtUtils-MakeMaker \
    redhat-lsb-core \
    readline-devel \
    tar \
    tbb \
    tbb-devel \
    wget \
    which \
    zlib \
    zlib-devel && \
    yum clean -y all && \
    rm -rf /var/cache/yum && \
    groupadd -g 1200 -r nexo && useradd -u 1200 --no-log-init -m -r -g nexo nexo  && \
    mkdir -p $NEXOTOP

WORKDIR $NEXOTOP

COPY --from=intermediate /nexo-env $NEXOTOP/nexo-env
COPY --from=intermediate /ExternalInterface $NEXOTOP/ExternalInterface
COPY --from=intermediate /sniper $NEXOTOP/sniper

RUN chown -R nexo $NEXOTOP && \
    chgrp -R nexo $NEXOTOP
    
USER nexo

#export PATH=$NEXOTOP/ExternalLibs/Python/3.7.7/bin:$PATH && \

RUN chmod ug+x nexo-env/nexoenv && chmod ug+x nexo-env/*.sh && \
    echo "Environment: \n" && env | sort && \
    export PATH=$NEXOTOP/nexo-env:$PATH && \
    nexoenv libs all python && \
    ln -s $NEXOTOP/ExternalLibs/Python/3.7.7/include/python3.7m $NEXOTOP/ExternalLibs/Python/3.7.7/include/python3.7 && \
    nexoenv libs all boost && \
    nexoenv libs all cmake && \
    nexoenv libs all xercesc && \
    nexoenv libs all gsl && \
    nexoenv libs all gccxml && \
    nexoenv libs all ROOT && \
    nexoenv libs all geant4 && \
    nexoenv libs all vgm && \
    nexoenv libs all cmt && \
    cd $NEXOTOP && \
    nexoenv env && \
    nexoenv cmtlibs && \
    rm -Rf $NEXOTOP/ExternalLibs/Build && \
    source $NEXOTOP/bashrc.sh && \
    mkdir sniper-build && \
    cd sniper-build && \
    cmake -DCMAKE_INSTALL_PREFIX=../sniper-install -DPYTHON_LIBRARY=$NEXO_EXTLIB_Python_HOME/lib/libpython3.7m.so -DPYTHON_INCLUDE_DIR=$NEXO_EXTLIB_Python_HOME/include/python3.7m -DBoost_NO_SYSTEM_PATHS=ON -DBOOSTROOT=$NEXO_EXTLIB_Boost_HOME -DBoost_PYTHON_LIBRARY_RELEASE=$NEXO_EXTLIB_Boost_HOME/lib/libboost_python37.so -DCMAKE_CXX_FLAGS=" -std=c++11 " -DUSE_SIMPLE_DIRS=ON ../sniper && \
    make && \
    make install && \
    cd .. && \
    rm /opt/nexo/software/sniper-install/python/Sniper/__init__.py && \
    echo -e "import sys\nsys.setdlopenflags( 0x100 | 0x2 ) # RTLD_GLOBAL | RTLD_NOW\nfrom Sniper.libSniperPython import *\nfrom Sniper import PyAlgBase" > /opt/nexo/software/sniper-install/python/Sniper/__init__.py && \
    source $NEXOTOP/ExternalLibs/Python/3.7.7/etc/profile.d/conda.sh && \
    conda activate root && \
    conda install -c conda-forge -y pyyaml && \
    rm setup.* && \
    mv bashrc.sh setup-externals.sh && \
    mv tcshrc.csh setup-externals.csh && \
    echo -e "source /opt/nexo/software/setup-externals.sh\nsource /opt/nexo/software/sniper-install/setup.sh\n" > /opt/nexo/software/setup-env.sh && \
    echo "source /opt/nexo/software/setup-env.sh" >> ~/.bashrc


# ENV NEXO_OFFLINE_OFF 1
CMD ["/bin/bash"]



