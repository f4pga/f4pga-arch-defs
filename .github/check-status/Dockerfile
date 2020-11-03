FROM python:alpine

RUN apk add git && pip install PyGithub git+https://github.com/SymbiFlow/symbiflow-tools-data-manager#egg=stdm --progress-bar off

COPY check-status.py /check-status.py
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
