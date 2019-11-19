FROM centos:7 as intermediate
RUN yum update -y && \
    yum install -y bash \
    git

ARG GH_USER
ARG GH_TOKEN

RUN git clone https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-env.git && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-offline.git && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-ei.git && \
    mv nexo-ei ExternalInterface && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/NESTCollaboration/nest.git && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/SNiPER-Framework/sniper.git

FROM centos:7 as runtime
MAINTAINER Heather Kelly <heather@slac.stanford.edu>

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
    zlib-devel 

RUN yum clean -y all

RUN rm -rf /var/cache/yum

RUN groupadd -g 1200 -r nexo && useradd -u 1200 --no-log-init -m -r -g nexo nexo 
ENV NEXOTOP /opt/nexo/software

RUN mkdir -p $NEXOTOP

WORKDIR $NEXOTOP

COPY --from=intermediate /nexo-env $NEXOTOP/nexo-env
COPY --from=intermediate /nexo-offline $NEXOTOP/nexo-offline
COPY --from=intermediate /ExternalInterface $NEXOTOP/ExternalInterface
COPY --from=intermediate /nest $NEXOTOP/nest
COPY --from=intermediate /sniper $NEXOTOP/sniper

RUN chown -R nexo $NEXOTOP
RUN chgrp -R nexo $NEXOTOP
USER nexo
RUN chmod ug+x nexo-env/nexoenv && chmod ug+x nexo-env/*.sh


RUN echo "Environment: \n" && env | sort

RUN export PATH=$NEXOTOP/nexo-env:$PATH && \
    nexoenv libs all python && \
    nexoenv libs all boost && \
    nexoenv libs all cmake && \
    nexoenv libs all xercesc && \
    nexoenv libs all gsl && \
    nexoenv libs all gccxml && \
    nexoenv libs all ROOT

# G4 download fails sometimes?
RUN export PATH=$NEXOTOP/nexo-env:$PATH && \
    nexoenv libs all geant4 && \
    nexoenv libs all vgm && \
    mkdir $NEXOTOP/ExternalLibs/Build/NEST && \
    mv $NEXOTOP/nest $NEXOTOP/ExternalLibs/Build/NEST/2.0 && \
    nexoenv libs all NEST && \
    nexoenv libs all cmt 


RUN export PATH=$NEXOTOP/nexo-env:$PATH \ 
    && cd $NEXOTOP \
    && nexoenv env \
    && nexoenv cmtlibs \
    && nexoenv sniper \
    && nexoenv offline

RUN cd $NEXOTOP \
    && export PATH=$NEXOTOP/ExternalLibs/Python/2.7.15/bin:$PATH \
    && pip install pyyaml \
    && ln -s /opt/nexo/software/sniper/InstallArea/Linux-x86_64/lib /opt/nexo/software/sniper/InstallArea/lib

ENV NEXO_OFFLINE_OFF 1

RUN rm -Rf $NEXOTOP/nexo-offline
RUN rm -Rf $NEXOTOP/ExternalLibs/Build


