#!/usr/bin/env sh

/check-status.py && mkdir install && symbiflow_get_latest_artifact_url > install/latest || echo '::set-output name=skip::true'
