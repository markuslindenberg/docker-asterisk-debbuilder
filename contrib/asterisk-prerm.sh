#!/bin/sh

systemctl --system stop asterisk.service || exit $?

