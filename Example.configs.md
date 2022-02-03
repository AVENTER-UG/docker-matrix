## Setup examples

These are example setups that can be used as a guide if you happen to use the same setup, or as a reference if your situation differs a bit.  
It is still highly recommended to read the [synapse readme](https://github.com/matrix-org/synapse/blob/master/README.rst) which goes in to much more detail. 

### Server at home behind NAT

The first thing we need is a DNS A record to your home IP (perferably a static IP, if you don't have that a dynamic dns service could work as well).

Once that's done we can generate the config files and self signed certificate:

   ` docker run -v /opt/synapse:/data --rm -e SERVER_NAME=example.com -e REPORT_STATS=no avhost/docker-matrix:latest generate`

At this point it's possible to edit the configuration file homeserver.yaml and turnserver.conf, located in this example in `/opt/synapse`  
In homeserver.yaml we may want to enable registration and
[recaptcha](https://github.com/matrix-org/synapse/blob/master/docs/CAPTCHA_SETUP.md)
In turnserver.conf we have to set the external ip and we can change the TURN portrange. The default TURN port range is
`49152-65535` but because docker doesn't like publishing large port ranges we'll decrease the portrange here.

    `external-ip=203.0.113.0`  
    `min-port=49152`  
    `max-port=49300`

The next step is to forward the relevant ports in the router to the server (note that docker by default writes iptables rules to open the ports needed):

`443, 8448` TCP for the matrix server (443 for clients 8448 for federation)  
`3478, 5349` TCP/UDP for STUN  
`49152-49300` TCP/UDP for TURN  

We now need to configure the webserver reverse proxy. This is done to allow clients to connect on the default 443 port and to use a valid certificate (for instance [letsencrypt](https://letsencrypt.org/docs/)).  
For more details on reverse proxy look at the documentation for the webserver of choice. Here we give an example config for apache2:  
First we need to enable mod_proxy and mod_proxy_http and mod_ssl, if you haven't already:  
`# a2enmod proxy proxy_http ssl`  
Then we can create the apache config for the subdomain using a reverse proxy by making /etc/apache2/sites-available/matrix.example.com-ssl.conf.  
This is an example of a resulting config. Note that letsencrypt should write part of the config using certbot.

```apache
<VirtualHost *:443>
    SSLEngine on
    ServerName matrix.example.com

    RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
    AllowEncodedSlashes NoDecode
    ProxyPreserveHost on
    ProxyPass /_matrix http://127.0.0.1:8008/_matrix nocanon
    ProxyPassReverse /_matrix http://127.0.0.1:8008/_matrix
    ProxyPass /_synapse/client http://127.0.0.1:8008/_synapse/client nocanon
    ProxyPassReverse /_synapse/client http://127.0.0.1:8008/_synapse/client
</VirtualHost>

<VirtualHost *:8448>
    SSLEngine on
    ServerName example.com

    RequestHeader set "X-Forwarded-Proto" expr=%{REQUEST_SCHEME}
    AllowEncodedSlashes NoDecode
    ProxyPass /_matrix http://127.0.0.1:8008/_matrix nocanon
    ProxyPassReverse /_matrix http://127.0.0.1:8008/_matrix
</VirtualHost>
```

For more examples: please have a look at the [synapse reverse proxy
readme](https://github.com/matrix-org/synapse/blob/master/docs/reverse_proxy.md)

Once the config is created we'll need to enable the site:  
`a2ensite matrix.example.com`

At this point we're ready to start the server:  
`docker run --name=matrix -d --restart=always -p 8448:8448 -p 8008:8008 -p 3478:3478 -p 3478:3478/udp -p 5349:5349/udp -p 5349:5349 -p 49152-49300:49152-49300/udp -p 49152-49300:49152-49300 -v /opt/synapse:/data avhost/docker-matrix:latest start`

After the container successfully started and the reverse proxy is configured we should be able to connect to the server using a matrix client and register a user (if that was enabled in the config).

If the client connected successfully we should check whether the federation works properly by going to:

`https://matrix.org/federationtester/api/report?server_name=example.com`

If everything checks out this means the synapse server is up and running.
