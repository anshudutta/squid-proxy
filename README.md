# squid-proxy

Squid proxy with ssl bump

## Build

### Certificates

Generate your own certificates and put it in

- `./certs/CA_crt.pem`
- `./certs/CA_key.pem`

OR

Generate self signed certificates

```bash
make cert
```

Intermediate certificates are placed in `certs/intermediate`. Add as necessary

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

Run Makefile

```bash
make test
```

E.g. - Allowed

```bash
docker exec squid-proxy_client_1 /bin/bash -c "curl https://google.com"            
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   220  100   220    0     0    286      0 --:--:-- --:--:-- --:--:--   286
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="https://www.google.com/">here</A>.
</BODY></HTML>
```

E.g - Denied

```bash
docker exec squid-proxy_client_1 /bin/bash -c "curl https://facebook.com"
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (35) Unknown SSL protocol error in connection to facebook.com:443 
```

Check logs

```bash
docker exec squid-proxy_server_1 /bin/bash -c "tail -f /apps/squid/var/logs/access.log" 
```

## Troubleshooting

TLS code: X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY

- [Install missing intermediate certificate](https://docs.diladele.com/faq/squid/fix_unable_to_get_issuer_cert_locally.html)
- [Squid Wiki](https://wiki.squid-cache.org/ConfigExamples/Intercept/SslBumpExplicit#Alternative_trust_roots)
