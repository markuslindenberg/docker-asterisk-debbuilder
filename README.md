# What is it?

This is a *Dockerfile* and shell script to create a Docker image that will, when run, build **unofficial** Debian Jessie packages of the current Asterisk 12 tarball including PJSIP 2.3.

# Usage

```
git clone https://github.com/markuslindenberg/docker-asterisk-debbuilder.git
cd docker-asterisk-debbuilder
docker build -t astbuild .
docker run astbuild
``` 

# Package notes

The packages are created using FPM (https://github.com/jordansissel/fpm) and don't follow the conventions of the official Asterisk and PJSIP Debian packages. Especially since FPM doesn't use `dpkg-shlibdeps`, the manually created libraray dependencies are sketch at best. I chose FPM because of it's ability to create packages on the fly with only one command invocation and without needing elaborate packaging work.

I really do like FPM, but think it's best used for packaging scripts and stuff that doesn't use dynamic linking. Nevertheless, the packages created by this `Dockerfile` do work fine. 
