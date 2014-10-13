FROM debian:jessie
MAINTAINER Markus Lindenberg <markus.lindenberg@gmail.com>

# Make Debconf less annoying
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV DEBCONF_NOWARNINGS yes

RUN apt-get update
RUN apt-get -y install build-essential pkg-config sudo curl ruby ruby-dev binutils-dev \
	libsrtp0-dev libssl-dev libspeex-dev libspeexdsp-dev \
	libgsm1-dev \
	subversion flex libxml2-dev libxslt1-dev libncurses5-dev libcurl4-openssl-dev libsqlite3-dev uuid-dev libjansson-dev \
	&& apt-get clean

# Install FPM (Effing Package Management)
RUN gem install fpm

# Create users
RUN adduser --system --home /usr/src build
RUN mkdir -p /usr/src/build /usr/src/packages
RUN chown -R build: /usr/src

# Add build script
ADD build.sh /usr/src/build.sh
ADD contrib /usr/src/contrib
WORKDIR /usr/src
CMD ["/usr/src/build.sh"]
