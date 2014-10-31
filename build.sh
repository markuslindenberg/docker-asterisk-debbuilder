#!/bin/bash

set -x -e

pjsip_url="http://www.pjsip.org/release/2.3/pjproject-2.3.tar.bz2"
asterisk_url="http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-13-current.tar.gz"

mountdir="/output"
builddir="/usr/src/build"
contribdir="/usr/src/contrib"
outdir="/usr/src/packages"

# Cleanup build directory
find ${builddir} -mindepth 1 -delete
find ${outdir} -mindepth 1 -delete

### PJPROJECT/PJSIP

# Download
sudo -u build curl "${pjsip_url}" | sudo -u build tar xj -C "${builddir}"

pjdir="$(basename $(find "${builddir}" -maxdepth 1 -mindepth 1 -type d -name 'pjproject*'))"
pjversion="$(echo ${pjdir} | awk -F '-' '{print $2;}')"

# Build

cd ${builddir}/${pjdir}
sudo -u build ./configure CFLAGS='-DPJ_HAS_IPV6=1' \
	--prefix=/usr \
	--enable-shared \
	--disable-sound \
	--disable-resample \
	--disable-video \
	--disable-opencore-amr \
	--with-external-speex \
	--with-external-gsm \
	--with-external-srtp

sudo -u build make dep
sudo -u build make

# Create Packages
sudo -u build mkdir -p ${builddir}/root/pjproject
sudo -u build make install DESTDIR=${builddir}/root/pjproject

sudo -u build fpm -s dir -t deb -n pjproject \
	-v "${pjversion}-1" --epoch 10 \
	-C ${builddir}/root/pjproject \
	-p ${outdir}/pjproject_VERSION_ARCH.deb \
	--description "PJ Project - multimedia communication library" \
	--category comm \
	--license "GPL2" \
	--url "http://www.pjsip.org/" \
	--after-install ${contribdir}/pjproject-postinst.sh \
	--after-remove ${contribdir}/pjproject-postrm.sh \
	-d "libsrtp0" \
	-d "libssl1.0.0" \
	-d "libspeex1" \
	-d "libspeexdsp1" \
	-d "libgsm1" \
	usr/lib

sudo -u build fpm -s dir -t deb -n pjproject-dev \
	-v "${pjversion}-1" --epoch 10 \
	-C ${builddir}/root/pjproject \
	-p ${outdir}/pjproject-dev_VERSION_ARCH.deb \
	--description "PJ Project - development headers" \
	--category libdevel \
	--license "GPL2" \
	--url "http://www.pjsip.org/" \
	-d "pjproject = 10:${pjversion}-1" \
	usr/include

# Clean up
cd ${builddir}
rm -rf ${builddir}/${pjdir}
rm -rf ${builddir}/root/pjproject

# Install packages
dpkg -i ${outdir}/pjproject*.deb

### ASTERISK

# Download
sudo -u build curl "${asterisk_url}" | sudo -u build tar xz -C "${builddir}" 

astdir="$(basename $(find "${builddir}" -maxdepth 1 -mindepth 1 -type d -name 'asterisk*'))"
astversion="$(echo ${astdir} | awk -F '-' '{print $2;}')"

# Build

cd ${builddir}/${astdir}
sudo -u build ./configure CFLAGS=-mtune=generic --host=x86_64-linux-gnu --build=x86_64-linux-gnu
sudo -u build make menuselect.makeopts
sudo -u build menuselect/menuselect --enable DONT_OPTIMIZE menuselect.makeopts
sudo -u build menuselect/menuselect --enable BETTER_BACKTRACES menuselect.makeopts
sudo -u build make

# Create Packages

sudo -u build mkdir -p ${builddir}/root/asterisk
# This will download sounds
sudo -u build make install DESTDIR=${builddir}/root/asterisk
sudo -u build make samples DESTDIR=${builddir}/root/asterisk
sudo -u build mkdir -p ${builddir}/root/asterisk/lib/systemd/system
sudo -u build cp ${contribdir}/asterisk.service ${builddir}/root/asterisk/lib/systemd/system/

sudo -u build fpm -s dir -t deb -n asterisk \
	-v "${astversion}-1" --epoch 10 \
	-C ${builddir}/root/asterisk \
	-p ${outdir}/asterisk_VERSION_ARCH.deb \
	--category comm \
	--license "GPL2" \
	--description "Open Source Private Branch Exchange (PBX)" \
	--url "http://www.asterisk.org/" \
	-d "systemd" \
	-d "adduser" \
	-d "pjproject >= 10:${pjversion}-1" \
	-d "libsrtp0" \
	-d "libssl1.0.0" \
	-d "libspeex1" \
	-d "libspeexdsp1" \
	-d "libxml2" \
	-d "libxslt1.1" \
	-d "libncurses5" \
	-d "libcurl3" \
	-d "libsqlite3-0" \
	-d "libuuid1" \
	-d "libjansson4" \
	--deb-suggests "asterisk-dev" \
	--after-install ${contribdir}/asterisk-postinst.sh \
	--after-remove ${contribdir}/asterisk-postrm.sh \
	--before-remove ${contribdir}/asterisk-prerm.sh \
	--config-files /etc/asterisk \
	-x usr/include \
	-x usr/sbin/safe_asterisk \
	-x /usr/share/man/man8/safe_asterisk \
	etc \
	lib \
	usr \
	var

sudo -u build fpm -s dir -t deb -n asterisk-dev \
	-v "${astversion}-1" --epoch 10 \
	-C ${builddir}/root/asterisk \
	-p ${outdir}/asterisk-dev_VERSION_ARCH.deb \
	--description "Development files for Asterisk" \
	--category devel \
	--license "GPL2" \
	--url "http://www.asterisk.org/" \
	-d "asterisk = 10:${astversion}-1" \
	usr/include

### Finish

# Cleanup build directory
find ${builddir} -mindepth 1 -delete

# Copy/sync repo to output volume (if mounted)
[[ -e $mountdir ]] && cp ${outdir}/*.deb ${mountdir}/

set +x
echo -e "\nBUILD FINISHED\n"
if [[ -e $mountdir ]]; then
	echo "Packages were copied to mountpoint ${mountdir}"
else
	echo "You can copy the packages folder from the conatiner using:"
	echo -e "\ndocker cp ${HOSTNAME}:/usr/src/packages <destination>\n"
fi

