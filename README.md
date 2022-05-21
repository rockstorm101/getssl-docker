# getssl Docker Image

Simple image to periodically update SSL certificates using [`getssl`][1].

 - Small footprint: less than 10 MB image size.
 - Runs automatically at given times.
 - Simple configuration. See [`getssl`][1].

[1]: https://github.com/srvrco/getssl

## Usage

```
docker run --detach \
  --volume="getssl:/root/.getssl" \
  --volume="/path/to/webroot:/srv/html" \
  --volume="/path/to/certs:/srv/certs" \
  rockstorm/getssl
```

Three volumes are mounted, one containing the getssl configuration
files, one to give getssl access to the location where the ACME
challenge tokens will be placed and a third to give getssl access to
where the SSL certificates are to be stored.

By default, getssl will be run once a week. Mount a custom `crontab`
file at `/var/spool/cron/crontabs/root` to change this behaviour.

### Run Standalone getssl

To run getssl only once and exit the container, for example, to
generate initial default configuration files:

```
docker run --rm -v="$PWD:/root" rockstorm/getssl getssl -c yourdomain.com
```

## Examples
### Simple Nginx HTTPS Web Server 

This example consists of two containers running in parallel. Nginx
serves simple static content over HTTPS and getssl runs next to it
periodically updating the SSL certificates.

```
 container       filesystem         container
 +--------+   +-----------------+   +--------+
 |        | <-|     webroot     | <-|        |
 | nginx  |   +-----------------+   | getssl |
 | server |   +-----------------+   |        |
 |        | <-|      certs      | <-|        |
 |        |   +-----------------+   |        |
 |        |   +------+ +--------+   |        |
 |        | <-| conf | | getssl |-> |        |
 +--------+   +------+ +--------+   +--------+
```

This example mounts a total of 4 files/folders. 'webroot' and 'certs'
mounted on both containers, 'nginx.conf' to configure the Nginx container
and the 'getssl' folder which holds the getssl configuration
files. Structured on a docker-compose.yml file this looks like:

```yaml
services:
  nginx-server:
    ...
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./webroot:/usr/share/nginx/html:ro
      - ./certs:/etc/nginx/certs:ro 

  getssl:
    ...
    volumes:
      - ./getssl:/root/.getssl
      - ./webroot:/srv/html
      - ./certs:/srv/certs
```

#### 1. Setup and Configuration

Create the folder structure:

```
mkdir webroot certs getssl
```

Create simple content to serve on the web server:

```
echo "Hello, World!" > webroot/index.html
```

Create a basic configuration file for Nginx and save it as
`nginx.conf`.

Generate dummy self-signed certificates[^1] and place them under
`certs`:

```
DOMAIN="yourdomain.com"; \
openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
  -keyout certs/${DOMAIN}.key \
  -out certs/${DOMAIN}.crt \
  -subj "/CN="
```

Run getssl once to create sample configuration files. (We add `--user
$(id -u):$(id -g)` so the produced files are owned by you instead of
root)

```
docker run --rm -v="$PWD/getssl:/tmp/getssl" \
  --user $(id -u):$(id -g) \
  rockstorm/getssl getssl -c yourdomain.com -w /tmp/getssl
```

Customise `getssl/getssl.cfg` and `getssl/yourdomain.com/getssl.cfg`.
Use the staging server for testing.

```
CA="https://acme-staging-v02.api.letsencrypt.org"
```
```
SANS="www.yourdomain.com"
ACL=('/srv/html/.well-known/acme-challenge')
USE_SINGLE_ACL="true"
DOMAIN_CERT_LOCATION="/srv/certs/yourdomain.com.crt" # this is domain cert
DOMAIN_KEY_LOCATION="/srv/certs/yourdomain.com.key" # this is domain key
```

#### 2. Debug Setup

Launch the stack:

```
docker-compose up -d
```

Check you can access your server at `yourdomain.com`. You should see
the "Hello, World!".

Shell into the getssl container:

```
docker exec -it getssl /bin/sh
```

Run `getssl` to test it all goes well (add `-d` if you want to run in
debug mode):

```
getssl -a -U
```

You should get:

```
Verification completed, obtaining certificate.
[...]
Certificate saved in /root/.getssl/yourdomain.com/yourdomain.com.crt
copying domain certificate to /srv/certs/yourdomain.com.crt
copying private key to /srv/certs/yourdomain.com.key
/root/.getssl/yourdomain.com/yourdomain.com.crt not returned by server
getssl: yourdomain.com - rsa certificate obtained but not installed on server
```

Restart the web server:

```
docker restart nginx-server
```

If you now access your server at `https://yourdomain.com` you should
see that HTTPS works but throws a warning saying your certificate has
an unknown issuer ((STAGING) Let's Encrypt). Ignoring the warning
should let you see the "Hello, World!".

Running `getssl` again should throw:
```
yourdomain.com: certificate is valid for more than 30 days (until MMM DD HH:MM:SS YYYY GMT)
```

Once ready for production one would set the real server in
`getssl/getssl.cfg` and run getssl again to obtain a valid
certificate.

#### 3. Run Automatically

If undisturbed, `getssl` will run once a week. The web server would
need manual restart/reload to read the new certificates.


## Credits

How to setup [Alpine Linux][3] containers to run cron jobs by [Jason
Kulatunga][2].


## License

View [license information][8] for the software contained in this
image.

As with all Docker images, these likely also contain other software
which may be under other licenses (such as Bash, etc from the base
distribution, along with any direct or indirect dependencies of the
primary software being contained).

As for any pre-built image usage, it is the image user's
responsibility to ensure that any use of this image complies with any
relevant licenses for all software contained within.

[8]: https://github.com/rockstorm101/getssl-docker/blob/master/LICENSE


[^1]: https://stackoverflow.com/a/41366949


[2]: https://blog.thesparktree.com/cron-in-docker
[3]: https://alpinelinux.org
