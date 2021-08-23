TAG=$(shell git rev-parse --short HEAD)

build:
	rm CA_*.pem || true
	openssl genrsa -out CA_key.pem 2048
	docker run -it --rm -v $(PWD):/apps -w /apps alpine/openssl req -x509 -days 600 -new -nodes -key CA_key.pem -out CA_crt.pem -extensions v3_ca -config config/openssl.conf -subj "/C=US/ST=California/L=Mountain View/O=Squid/OU=Enterprise/CN=SquidCA"
	docker run --rm -i hadolint/hadolint < Dockerfile
	docker build . -t $(REPO)/squid-proxy:$(TAG)
	
push:
	docker push $(REPO)/squid-proxy:$(TAG)

stop:
	docker stop squid
	docker rm squid

run:
	docker run -d --name squid -p 3128:3128 $(REPO)/squid-proxy:$(TAG)
	docker exec squid /bin/bash -c "tail -f /apps/squid/var/logs/access.log"
