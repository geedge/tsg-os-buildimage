#!/usr/bin/env sh
pwd
ls -halt $CI_PROJECT_DIR
ls -halt $CI_PROJECT_DIR/images/
cat $CI_PROJECT_DIR/images/*.sha256sum.txt
if [ -n "${UPLOAD_TO_FILE_REPO}" ]; then	
	python3 ~/file_upload_tools.py ${PULP3_FILE_REPO_NAME} ${PULP3_FILE_DIST_NAME} ./images/*.bin
	python3 ~/file_upload_tools.py ${PULP3_FILE_REPO_NAME} ${PULP3_FILE_DIST_NAME} ./images/*.sha256sum.txt
fi