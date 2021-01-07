FROM continuumio/miniconda3:4.7.12 
LABEL maintainer="yannc@jfrog.com"

ARG ARTY_URL
ARG ARTY_USER
ARG ARTY_APIKEY

ARG BUILD_NAME='test_conda'
ARG BUILD_NUMBER='1'
ARG ARTY_MAIN_REPO='eva-conda'

# hack to pass variables to ENTRYPOINT
ENV B_NAME=$BUILD_NAME
ENV B_NUMBER=$BUILD_NUMBER
ENV ART_REPO=$ARTY_MAIN_REPO

ENV PKG_CACHE=/opt/conda/pkgs
ENV ARTY_ID='art'
ENV JFROG_CLI_OFFER_CONFIG=false


WORKDIR /tmp

RUN apt-get install -y curl git

RUN curl -fL https://getcli.jfrog.io | sh &&  chmod 755 jfrog &&  mv jfrog /usr/local/bin/

RUN jfrog rt c --interactive=false --url=$ARTY_URL --user=$ARTY_USER --apikey=$ARTY_APIKEY $ARTY_ID

RUN git clone https://github.com/cyan21/conda-pipeline.git

RUN chmod u+x conda-pipeline/scripts/init.sh conda-pipeline/scripts/build.sh

RUN conda-pipeline/scripts/init.sh -u $ARTY_USER -k $ARTY_APIKEY -l $ARTY_URL -r $ARTY_MAIN_REPO 

ENTRYPOINT ["/bin/bash", "-c", "cd conda-pipeline && scripts/build.sh -i $B_NAME -n $B_NUMBER -c $PKG_CACHE -r $ART_REPO -a $ARTY_ID"]
