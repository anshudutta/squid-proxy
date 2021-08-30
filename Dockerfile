ARG REPO
ARG TAG
ARG SQUID_VERSION

FROM ${REPO}/squid-proxy:certificates-${TAG} AS cert
FROM debian:stretch-slim

# hadolint ignore=SC2034
RUN apt-get update -y \
	&& apt-get install -y  --no-install-recommends \
	supervisor=3.3.1-1+deb9u1 \
	openssl=1.1.0l-1~deb9u3  \
	build-essential=12.3 \
	libssl-dev=1.1.0l-1~deb9u3 \
	ca-certificates=20200601~deb9u2 \
	curl=7.52.1-5+deb9u15 \
	wget=1.18-5+deb9u3 \
	iputils-ping=3:20161105-1 \
	libnet-nslookup-perl=2.04-1 \
	traceroute=1:2.1.0-2 \
	&& rm -rf /var/lib/apt/lists/* \
	&& mkdir -p /var/log/supervisor

COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN groupadd -g 1000 apps && useradd -u 1000 -g apps -s /apps apps

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

COPY --from=cert /usr/local/share/ca-certificates/* /usr/local/share/ca-certificates
RUN update-ca-certificates --fresh

COPY certs/CA_key.pem /apps/
COPY certs/CA_crt.pem /apps/
COPY config/squid.conf /apps/
COPY config/whitelist.txt /apps/

RUN chown -R nobody:nogroup /apps/ && \
	mkdir -p /apps/squid/var/lib/ && \
	/apps/squid/libexec/security_file_certgen -c -s /apps/squid/var/lib/ssl_db -M 4MB && \
	/apps/squid/sbin/squid -N -f /apps/squid.conf -z && \
	chown -R apps:apps /apps/ 

USER apps

EXPOSE 3128

ENTRYPOINT [ "/apps/squid/sbin/squid" ] 
CMD [ "-NsY", "-f", "/apps/squid.conf" ]
