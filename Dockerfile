ARG SQUID_VERSION

FROM debian:stretch-slim

# hadolint ignore=SC2034
RUN apt-get update -y \
	&& apt-get install -y  --no-install-recommends \
	supervisor=3.3.1-1+deb9u1 \
	openssl=1.1.0l-1~deb9u3  \
	build-essential=12.3 \
	libssl-dev=1.1.0l-1~deb9u3 \
	ca-certificates=20200601~deb9u2 \
	wget=1.18-5+deb9u3 \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /var/log/supervisor

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
WORKDIR /apps/
ARG SQUID_VERSION=4.16
# hadolint ignore=DL3003
RUN wget --progress=dot:giga http://www.squid-cache.org/Versions/v4/squid-${SQUID_VERSION}.tar.gz \
	&& tar zxfv squid-${SQUID_VERSION}.tar.gz \
	&& CPU=$(( `nproc --all`-1 )) \
	&& cd /apps/squid-${SQUID_VERSION} \
	&& ./configure --prefix=/apps/squid --enable-icap-client --enable-ssl --with-openssl --enable-ssl-crtd --enable-auth --enable-basic-auth-helpers="NCSA" \
	&& make -j$CPU \
	&& make install \
	&& cd /apps \
	&& rm -rf /apps/squid-${SQUID_VERSION}

COPY certificates/Intermediate.pem /usr/local/share/ca-certificates/Intermediate.crt
RUN update-ca-certificates --fresh

COPY certificates/*.pem /apps/
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
