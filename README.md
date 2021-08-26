# squid-proxy

Squid proxy with ssl bump

## Build

### Certificates

Generate your own certificates and put it in

- `./certificates/CA_crt.pem`
- `./certificates/CA_key.pem`

OR

Generate self signed certificates

```bash
make cert
```

### Image

```bash
make build PWD=$(pwd) REPO=<your-repo>
```

### Configure

The `./config/whitelist` has the allowed list of domains. Make changes as necessary.

## Push

[Use pre-built images](https://hub.docker.com/repository/docker/anshudutta/squid-proxy)

Or, make your own

```bash
make push REPO=<your-repo>
```

## Test

```bash
docker-compose up -d --build
docker exec -it squid-proxy_client_1 /bin/bash
```

Now from the terminal run

Allowed

```bash
curl https://google.com
```

Blocked

```bash
curl https://facebook.com
```

Check logs

```bash
docker exec squid-proxy_server_1 /bin/bash -c "tail -f /apps/squid/var/logs/access.log" 
```

## Troubleshooting

TLS code: X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY

- [Install missing intermediate certificate](https://docs.diladele.com/faq/squid/fix_unable_to_get_issuer_cert_locally.html)
- [Squid Wiki](https://wiki.squid-cache.org/ConfigExamples/Intercept/SslBumpExplicit#Alternative_trust_roots)
