#! /bin/sh

set -e

case "$1" in
    configure)
    	# add asterisk user
	if ! getent passwd asterisk > /dev/null ; then
		echo 'Adding system user for Asterisk' 1>&2
		adduser --system --group --quiet \
			--home /var/lib/asterisk \
			--no-create-home --disabled-login \
			--gecos "Asterisk PBX daemon" \
			asterisk
	fi

	# chown asterisk on all $dirs and their subdirectories
	# do not harm the files, they should be empty on new installations
	# and we don't want to mess-up anything on old installations
	find /var/log/asterisk \
	     /var/lib/asterisk \
	     -type d | while read dir; do
		if ! dpkg-statoverride --list "$dir" > /dev/null ; then
			chown asterisk: "$dir"
		fi
	done 

	# this is not needed for new installations but is not such a bad idea
	# removing this will _break_ upgrades from versions < 1:1.4.10.1~dfsg-1
	#
	# we are doing the same for subdirectories, since we are not shipping
	# any and it's supposed to be user-modifiable
	if ! dpkg-statoverride --list "/etc/asterisk" > /dev/null ; then
		chown asterisk: /etc/asterisk
	fi

	# spool holds some sensitive information (e.g. monitor, voicemail etc.)
	find /var/spool/asterisk -type d | while read dir; do
		if ! dpkg-statoverride --list "$dir" > /dev/null ; then
			chown asterisk: "$dir"
			chmod 750 "$dir"
		fi
	done

	systemctl --system daemon-reload >/dev/null || true
	systemctl --system enable asterisk.service

    ;;

    abort-upgrade|abort-remove|abort-deconfigure)
    ;;

    *)
        echo "postinst called with unknown argument \`$1'" >&2
        exit 1
    ;;
esac

exit 0

