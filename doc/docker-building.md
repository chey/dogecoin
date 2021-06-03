# Docker building


## Alpine

Steps for producing a working Docker image based on Alpine Linux.


### Build image

```
docker build -t dogecoin -f alpine.Dockerfile .
```

By default the `latest` version of Alpine Linux will be used.

To test with another version of Alpine Linux use the Docker `--build-arg` argument to specify the version.

For example:
```
docker build --build-arg ALPINE_VERSION=3.8 -t dogecoin -f alpine.Dockerfile .
```

### Run image

Start daemon
```
docker run -it --rm --name dogecoin -d dogecoin -printtoconsole
```

Getinfo
```
docker exec -it dogecoin dogecoin-cli getinfo
```

Check logs
```
docker logs dogecoin -f
```
