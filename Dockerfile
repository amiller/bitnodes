FROM ubuntu:14.04

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -qy htop sudo unzip build-essential tcl subversion
RUN apt-get install -qy software-properties-common curl git python2.7 python-pip python-dev libpython-dev libssl-dev libffi-dev pkg-config autoconf libtool wget

# Redis
ENV REDIS_SOCKET /tmp/redis.sock
ENV REDIS_PASSWORD REDISPASS
ENV REDIS_VERSION 3.0.7
ENV REDIS_DOWNLOAD_URL http://download.redis.io/releases/redis-3.0.7.tar.gz
ENV REDIS_DOWNLOAD_SHA1 e56b4b7e033ae8dbf311f9191cf6fdf3ae974d1c
RUN buildDeps='gcc libc6-dev make' \
    && set -x \
    && apt-get install -y $buildDeps --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && wget -O redis.tar.gz "$REDIS_DOWNLOAD_URL" \
    && echo "$REDIS_DOWNLOAD_SHA1 *redis.tar.gz" | sha1sum -c - \
    && mkdir -p /usr/src/redis \
    && tar -xzf redis.tar.gz -C /usr/src/redis --strip-components=1 \
    && rm redis.tar.gz \
    && make -C /usr/src/redis \
    && make -C /usr/src/redis install \
    && rm -r /usr/src/redis
ENV REDIS_CLI "redis-cli -s $REDIS_SOCKET -a $REDIS_PASSWORD"

COPY redis-0.conf /etc/redis/0.conf

RUN wget --no-check-certificate https://github.com/ayeowch/bitnodes/archive/master.zip
RUN unzip master.zip
WORKDIR bitnodes-master
#RUN git clone https://github.com/ayeowch/bitnodes
#WORKDIR bitnodes
RUN pip install -r requirements.txt

#CMD bash -c 'redis-server "/etc/redis/0.conf" &; $REDIS_CLI'

RUN bash geoip/update.sh
# RUN bash start.sh

VOLUME ['data/']
COPY crawl.testnet3.conf crawl.testnet3.conf
COPY start.sh start.sh
CMD bash -c 'nohup sh -c "redis-server /etc/redis/0.conf" &'  \
    && ./start.sh \
    && bash
#    && python -m SimpleHTTPServer 8081

# Pcap all the things
#RUN cd data/pcap
#RUN sudo rm *.pcap; sudo tcpdump -i eth0 -w %s.eth0.pcap -v -n -G 3 -B 65536 -Z [USERNAME] 'tcp and not src host [IP_ADDRESS] and not src host [IPV6_ADDRESS]' > eth0 2>&1 &
#sudo tcpdump -i lo -w %s.lo.pcap -v -n -G 3 -B 65536 -Z [USERNAME] 'tcp and port 9050' > lo 2>&1 &

#RUN apt-get purge -y --auto-remove $buildDeps
