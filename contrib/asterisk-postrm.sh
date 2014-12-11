#!/bin/sh

set -e

if [ "$1" = purge ]; then
	userdel -r asterisk 2>/dev/null || true
	rm -fR /var/log/asterisk
fi

systemctl --system daemon-reload >/dev/null || true

