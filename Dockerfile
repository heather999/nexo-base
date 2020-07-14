#FROM centos:7 as intermediate
#FROM nvidia/cuda:10.2-runtime-centos7 as intermediate
FROM nvidia/cuda:10.2-cudnn7-devel-centos7 as intermediate
RUN yum update -y && \
    yum install -y bash \
    git

ARG GH_USER
ARG GH_TOKEN

RUN git clone -b pytorch-noconda https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-env.git && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-ei.git && \
    mv nexo-ei ExternalInterface && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/SNiPER-Framework/sniper.git

#FROM centos:7 as runtime
#FROM nvidia/cuda:10.2-runtime-centos7 as runtime
FROM nvidia/cuda:10.2-cudnn7-devel-centos7 as runtime
MAINTAINER Heather Kelly <heather@slac.stanford.edu>

ENV NEXOTOP /opt/nexo/software

RUN yum update -y && \
    yum install -y bash \
    bison \
    blas \
    bzip2-devel \
    bzip2 \
    centos-release-scl-rh \
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
    lzma \
    lzma-devel \
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
    zlib-devel 
    
RUN yum install -y devtoolset-8-gcc devtoolset-8-gcc-c++ && \
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
#    conda install --freeze-installed -c conda-forge -y pyyaml && \
#    conda install -c pytorch -c conda-forge -y numpy==1.19.0 pytorch torchvision cpuonly && \

RUN chmod ug+x nexo-env/nexoenv && chmod ug+x nexo-env/*.sh && \
    gcc --version && \
    echo "Environment: \n" && env | sort && \
    export PATH=$NEXOTOP/nexo-env:$PATH && \
    nexoenv libs all python && \
    ln -s $NEXOTOP/ExternalLibs/Python/3.6.8/include/python3.6m $NEXOTOP/ExternalLibs/Python/3.6.8/include/python3.6 && \
    ln -s $NEXOTOP/ExternalLibs/Python/3.6.8/bin/python3 $NEXOTOP/ExternalLibs/Python/3.6.8/bin/python && \
    ln -s $NEXOTOP/ExternalLibs/Python/3.6.8/bin/pip3 $NEXOTOP/ExternalLibs/Python/3.6.8/bin/pip && \
    export PATH=$NEXOTOP/ExternalLibs/Python/3.6.8/bin:$PATH && \
    export LD_LIBRARY_PATH=$NEXOTOP/ExternalLibs/Python/3.6.8/lib:$PATH && \
    ls $NEXOTOP/ExternalLibs/Python && \ 
    ls $NEXOTOP/ExternalLibs/Python/3.6.8 && \
    which python && \ 
    which pip && \
    pip install torch==1.5.1+cpu torchvision==0.6.1+cpu -f https://download.pytorch.org/whl/torch_stable.html && \
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
    cmake -DCMAKE_INSTALL_PREFIX=../sniper-install -DPYTHON_LIBRARY=$NEXO_EXTLIB_Python_HOME/lib/libpython3.6m.so -DPYTHON_INCLUDE_DIR=$NEXO_EXTLIB_Python_HOME/include/python3.6m -DBoost_NO_SYSTEM_PATHS=ON -DBOOSTROOT=$NEXO_EXTLIB_Boost_HOME -DBoost_PYTHON_LIBRARY_RELEASE=$NEXO_EXTLIB_Boost_HOME/lib/libboost_python3.so -DCMAKE_CXX_FLAGS=" -std=c++11 " -DUSE_SIMPLE_DIRS=ON ../sniper && \
    make && \
    make install && \
    cd .. && \
    rm /opt/nexo/software/sniper-install/python/Sniper/__init__.py && \
    echo -e "import sys\nsys.setdlopenflags( 0x100 | 0x2 ) # RTLD_GLOBAL | RTLD_NOW\nfrom Sniper.libSniperPython import *\nfrom Sniper import PyAlgBase" > /opt/nexo/software/sniper-install/python/Sniper/__init__.py && \
    echo -e "source /opt/nexo/software/bashrc.sh\nsource /opt/nexo/software/sniper-install/setup.sh\n" > /opt/nexo/software/setup-tobuild.sh && \
    echo -e "source /opt/nexo/software/bashrc.sh\nsource /opt/nexo/software/sniper-install/setup.sh\nsource /opt/nexo/software/nexo-offline-build/setup.sh" > /opt/nexo/software/setup-all.sh


# ENV NEXO_OFFLINE_OFF 1


# ENV NEXO_OFFLINE_OFF 1

