# Example configuration files

Command:
```shell
./cloudprober -config_file=[CONFIG_FILE]
```

Example:
```shell
./cloudprober -config_file=examples/example_validator_probe_config.cfg
```

Cloudprober probe configuration:

* DNS: `example_dns_probe_config.cfg`
	* Send DNS requests to Google `8.8.8.8` and Cloudflare `1.1.1.1` DNS server
	* DNS query types `A` (IPv4), `AAAA` (IPv6) and `NS` (Name Server)
	* Validate DNS name server from Domain `nkn-it.de`
	* 👍 This probe should succeed
* Custom HTTPS cert and port: `example_http_probe_config.cfg`
	* More hosts
	* HTTPS
	* Disable TLS certificate validation
	* Port for HTTP request: `50000`
	* Relative URL / path and parameter: `/exposed?action=ping`
	* 👎 This probe should fail (unknown hosts `server1`...)
* POST: `example_post_probe_config.cfg`
	* HTTPS with TLS certificate validation
	* HTTP Method: `POST`
	* Default port: `443`
	* Relative URL / path and parameter: `/post`
	* 👍 This probe should succeed
* Check return code : `example_status_code_probe_config.cfg`
	* HTTPS with TLS certificate validation
	* Default port: `443`
	* Relative URL / path and parameter: `/status/403`
	* Check status code to match: `400-499`
	* 👍 This probe should succeed
* Check output : `example_validator_probe_config.cfg`
	* HTTPS with TLS certificate validation
	* Default port: `443`
	* Relative URL / path and parameter: `/ci.txt`
	* Check output to match a certain regex: `3.14159`
	* 👍 This probe should succeed
