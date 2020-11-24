#!/usr/bin/env sh

mkdir install && /check-status.py || echo '::set-output name=skip::true'
