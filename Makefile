TAG=$(shell git rev-parse --short HEAD)

cert:
	rm ./certificates/CA_*.pem || true
	openssl genrsa -out ./certs/CA_key.pem 2048
	docker run -it --rm -v $(PWD):/apps -w /apps alpine/openssl req -x509 -days 600 -new -nodes -key ./certs/CA_key.pem -out ./certs/CA_crt.pem -extensions v3_ca -config ./certs/openssl.conf -subj "/C=US/ST=California/L=Mountain View/O=Squid/OU=Enterprise/CN=SquidCA"
	
build:
	docker run --rm -i hadolint/hadolint < Dockerfile
	docker build . -f Dockerfile.certificates -t $(REPO)/squid-proxy:certificates-$(TAG)
	docker build . --build-arg REPO=$(REPO) --build-arg TAG=$(TAG) -t $(REPO)/squid-proxy:server-$(TAG)
	
push:
	docker push $(REPO)/squid-proxy:certificates-$(TAG)
	docker push $(REPO)/squid-proxy:server-$(TAG)

stop:
	docker stop squid
	docker rm squid

run:
	docker run -d --name squid -p 3128:3128 $(REPO)/squid-proxy/server:$(TAG)
	docker exec squid /bin/bash -c "tail -f /apps/squid/var/logs/access.log"

test:
	docker-compose up -d --build
	docker-compose ps
	docker exec squid-proxy_client_1 /bin/bash -c "curl -v https://google.com" || true
	docker exec squid-proxy_client_1 /bin/bash -c "curl -v https://facebook.com" || true
	docker-compose down -v