# CrowdSec Dev Container

Development image based on **`ghcr.io/digital-drive/crowdsec-dev:1.7.0`**.  
This container provides a complete environment for testing and developing with CrowdSec.

## Quick Start

Clone the Hub repository locally:
```bash
git clone https://github.com/crowdsecurity/hub
```

Run the container while mounting the Hub repository:
```bash
docker run -it --rm   -v $(pwd)/hub:/crowdsec/tests/hub   digital-drive.io/crowdsec-dev:1.7.0 /bin/bash
```

The `hub` directory will be accessible at:
```
/crowdsec/tests/hub
```

## Commands

An alias **`csdev`** is preconfigured.  
It is a wrapper around `cscli` with all required paths already loaded.

Examples:
```bash
csdev metrics
csdev decisions list
csdev hub list
```

## Key points

- Base: `digital-drive.io/crowdsec-dev:1.7.0`
- Main working directory: `/crowdsec/tests`
- Volume to mount: [crowdsecurity/hub](https://github.com/crowdsecurity/hub) repository
- Main alias: `csdev` (equivalent to `cscli` with integrated configuration)

## Usage example

```bash
# Update the hub
cd /crowdsec/tests/hub
csdev hub update

# List scenarios
csdev scenarios list

# Check status
csdev metrics
```
