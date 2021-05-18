#!/usr/bin/env sh
pwd
ls -halt $CI_PROJECT_DIR
ls -halt $CI_PROJECT_DIR/images/
if [ -n "${UPLOAD_TO_FILE_REPO}" ]; then	
	python3 ~/file_upload_tools.py ${PULP3_FILE_REPO_NAME} ${PULP3_FILE_DIST_NAME} ./images/*.bin
fi