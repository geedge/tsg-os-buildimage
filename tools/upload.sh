#!/usr/bin/env sh
pwd
ls -halt $CI_PROJECT_DIR
ls -halt $CI_PROJECT_DIR/images/

#function define start
function upload_kvm_glob_file()
{
	python3 ~/file_upload_tools_to_share_repo.py ${FILE_REPO_PATH} ./images/*.img
	python3 ~/file_upload_tools_to_share_repo.py ${FILE_REPO_PATH} ./images/*.gns3a
}

function upload_app_bundle_glob_file()
{
	python3 ~/file_upload_tools_to_share_repo.py ${FILE_REPO_PATH} ./images/*-APP-BUNDLE.bin
	python3 ~/file_upload_tools_to_share_repo.py ${FILE_REPO_PATH} ./images/*-APP-BUNDLE.bin.sha256sum.txt
}

function upload_onie_glob_file()
{
	python3 ~/file_upload_tools_to_share_repo.py ${FILE_REPO_PATH} ./images/*-ONIE.bin
	python3 ~/file_upload_tools_to_share_repo.py ${FILE_REPO_PATH} ./images/*-ONIE.bin.sha256sum.txt
}

function is_upload_file()
{
	if [ ! -n "${UPLOAD_TO_FILE_REPO}" ]; then
		echo "Current job not set UPLOAD_TO_FILE_REPO variables"
		exit 0
	fi
}

function upload_file_by_profile_list()
{
	case ${PROFILE_LIST} in
		"KVM")
			upload_kvm_glob_file
			break
			;;
		"TSGXBUILDCONTAINERP0906")
			upload_app_bundle_glob_file
			break
			;;
		*)
			upload_onie_glob_file
			break
			;;
	esac
}
#function define end

is_upload_file
upload_file_by_profile_list
