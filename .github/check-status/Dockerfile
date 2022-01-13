FROM python:alpine

RUN apk update && apk add git gcc libc-dev libffi-dev && pip install PyGithub git+https://github.com/SymbiFlow/symbiflow-tools-data-manager#egg=stdm --progress-bar off

COPY check-status.py /check-status.py
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
