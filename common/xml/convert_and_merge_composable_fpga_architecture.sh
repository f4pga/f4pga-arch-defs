#!/bin/bash

set -euo pipefail

TOP_DIR=$(git rev-parse --show-toplevel)
XSLTPROC_CMD="${XSLTPROC} --nomkdir --nonet --xinclude ${XSLTPROC_PARAMS}"
${XSLTPROC_CMD} ${TOP_DIR}/common/xml/identity.xsl "$@"				  | \
	${XSLTPROC_CMD} ${TOP_DIR}/common/xml/convert-pb_type-attributes.xsl	- | \
	${XSLTPROC_CMD} ${TOP_DIR}/common/xml/convert-port-tag.xsl		- | \
	${XSLTPROC_CMD} ${TOP_DIR}/common/xml/convert-prefix-port.xsl		- | \
	${XSLTPROC_CMD} ${TOP_DIR}/common/xml/pack-patterns.xsl	 		- | \
	${XSLTPROC_CMD} ${TOP_DIR}/common/xml/remove-duplicate-models.xsl 	- | \
	${XSLTPROC_CMD} ${TOP_DIR}/common/xml/attribute-fixes.xsl 		- | \
	${XSLTPROC_CMD} ${TOP_DIR}/common/xml/sort-tags.xsl 			- | \
	cat
