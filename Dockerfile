ARG SQUID_VERSION

FROM debian:11
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y supervisor git openssl  build-essential libssl-dev wget vim curl \
    && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /var/log/supervisor
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
WORKDIR /apps/
ARG SQUID_VERSION=4.16
RUN wget http://www.squid-cache.org/Versions/v4/squid-${SQUID_VERSION}.tar.gz \
    && tar zxfv squid-${SQUID_VERSION}.tar.gz \
    && CPU=$(( `nproc --all`-1 )) \
    && cd /apps/squid-${SQUID_VERSION} \
    && ./configure --prefix=/apps/squid --enable-icap-client --enable-ssl --with-openssl --enable-ssl-crtd --enable-auth --enable-basic-auth-helpers="NCSA" \
    && make -j$CPU \
    && make install \
    && cd /apps \
    && rm -rf /apps/squid-${SQUID_VERSION} 

COPY *.pem /apps/
COPY config/squid.conf /apps/
COPY config/whitelist.txt /apps/

RUN chown -R nobody:nogroup /apps/ && \
    mkdir -p  /apps/squid/var/lib/ && \
    /apps/squid/libexec/security_file_certgen -c -s /apps/squid/var/lib/ssl_db -M 4MB && \
    /apps/squid/sbin/squid -N -f /apps/squid.conf -z && \
    chown -R nobody:nogroup /apps/ && \
    chgrp -R 0 /apps && chmod -R g=u /apps

EXPOSE 3128

ENTRYPOINT [ "/apps/squid/sbin/squid" ] 
CMD [ "-NsY", "-f", "/apps/squid.conf" ]
