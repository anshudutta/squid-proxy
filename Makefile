
build:
	rm CA_*.pem
	openssl genrsa -out CA_key.pem 2048
	docker run -it --rm -v $(pwd):/apps -w /apps alpine/openssl req -x509 -days 600 -new -nodes -key CA_key.pem -out CA_crt.pem -extensions v3_ca -config config/openssl.conf -subj "/C=US/ST=California/L=Mountain View/O=Squid/OU=Enterprise/CN=SquidCA"
	docker build . -t $(repo)/squid:latest
	
push:
	docker push $(repo)/squid:latest

run:
	docker run -d --name squid -p 3128:3128 $(repo)/squid:latest
	docker exec squid /bin/bash -c "tail -f /apps/squid/var/logs/access.log"