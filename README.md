# archlinux for docker

## Build

```bash
docker build -t minanon/archlinux .
```

## Run

```bash
docker run --rm -it minanon/archlinux
```

## script files

### make archlinux archive for docker image

You can get archlinux archive(archlinux.tar.xz) for docker image by `scripts/make_image_tar.sh` script.
It get archive from arch official sites. setting environment and re-compress for docker image.

#### useage

```bash
[repos_country=com|jp] [dl_domain=rackspace.com] [chpacman=true] ./scripts/make_image_tar.sh
```

##### options

Options are defined on environment.

|option name  |useage                                                                                                                  |
|---          |---                                                                                                                     |
|repos_country|Please set top domain for download archlinux. The script search download URL from this domain automatically. default: jp|
|dl_domain    |You can target download domain. It have priority than repos_country setting.                                            |
|chpacman     |If it is true, pacman mirrors of repos_country code top domain are enabled. default: true                               |
