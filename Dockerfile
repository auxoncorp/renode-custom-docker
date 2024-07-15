FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates sudo git automake \
    autoconf libtool g++ coreutils policykit-1 \
    libgtk2.0-dev uml-utilities python3 python3-pip \
    ruby ruby-dev rpm 'bsdtar|libarchive-tools' \
    dotnet-sdk-6.0
RUN gem install fpm

WORKDIR /
RUN git clone https://github.com/auxoncorp/renode --branch s32k3
WORKDIR /renode
RUN ./build.sh -p --net --no-gui
RUN cp output/packages/*.tar.gz /renode.tar.gz

# This is a modified version of https://raw.githubusercontent.com/renode/renode-docker/master/Dockerfile
# - Use a custom build of renode (above)
# - Added the RENODE_SCRIPT environment variable to pass a value to 'renode -e'
# - Use an entrypoint shell script to work around shutdown issues
FROM ubuntu:22.04
ARG DEBIAN_FRONTEND=noninteractive
ENV RENODE_SCRIPT=""

ENV TZ=Etc/UTC
# Install main dependencies and some useful tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates sudo wget git dotnet-sdk-6.0 python3-dev python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Set up users
RUN sed -i.bkp -e \
    's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' \
    /etc/sudoers
ARG userId=1000
ARG groupId=1000
RUN mkdir -p /home/developer && \
    echo "developer:x:$userId:$groupId:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:$userId:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown $userId:$groupId -R /home/developer

# Install Renode
COPY --from=0 /renode.tar.gz renode.tar.gz
COPY entrypoint-renode.sh /entrypoint-renode.sh

RUN tar xzmf renode.tar.gz && mkdir -p /opt && rm renode.tar.gz && mv renode* /opt/renode
RUN pip3 install -r /opt/renode/tests/requirements.txt --no-cache-dir

USER developer
ENV HOME=/home/developer
WORKDIR /home/developer
CMD ["/entrypoint-renode.sh"]
