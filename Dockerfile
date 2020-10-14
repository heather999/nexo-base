FROM heather999/nexo-base:latest as intermediate

ARG GH_USER
ARG GH_TOKEN

RUN cd /tmp && \
    git clone https://$GH_USER:$GH_TOKEN@github.com/nEXO-collaboration/nexo-offline.git 
    
FROM heather999/nexo-base:v4r2p0 as runtime
MAINTAINER Heather Kelly <heather@slac.stanford.edu>

ENV NEXOTOP /opt/nexo/software

#RUN groupadd -g 1200 -r nexo && useradd -u 1200 --no-log-init -m -r -g nexo nexo  && \
#    mkdir -p $NEXOTOP

WORKDIR $NEXOTOP

COPY --from=intermediate /tmp/nexo-offline $NEXOTOP/nexo-offline

#RUN chown -R nexo $NEXOTOP && \
#    chgrp -R nexo $NEXOTOP
    
USER nexo

RUN echo "Environment: \n" && env | sort && \
    cd $NEXOTOP && \
    source $NEXOTOP/bashrc.sh && \
    source $NEXOTOP/sniper-install/setup.sh && \
    mkdir $NEXOTOP/nexo-offline-build && \
    cd $NEXOTOP/nexo-offline-build && \
    cmake -DSNIPER_ROOT_DIR=/opt/nexo/software/sniper-install -DCMAKE_CXX_FLAGS="-std=c++11" ../nexo-offline && \
    make 
    

# ENV NEXO_OFFLINE_OFF 1



