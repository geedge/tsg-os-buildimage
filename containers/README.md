# Container Guide
## Description
The directories for containers serve the purpose of obtaining container image tar files. You can get these image tar files through a Dockerfile, by pulling images from a registry, or by downloading tar files from URLs and other sources. There are many directories, with each one corresponding to a specific job. One job can depend on another job.
## Structure
The job structure of Container  is as follows:
```
dirs/
    files/
    templates/
    build.mk
    Dockerfile.j2
    entrypoint.sh
    manifest.yaml
```
### files/
Contains files used with the copy resource.
### templates/
Contains files used with the template resource.
### build.mk
The `build.mk` file is included by the top-level Makefile in the containers directory for builds. `build.mk` defines `Makefile rules`, which generate both `file targets`(build/{{rule_name}}/build.done) and `phony targets`. This file supports the following variables, allowing you to set these variables to modify the content of the Makefile rules.
```
rule_name              # Makefile rule name.
rule_prerequisites:    # Makefile rule prerequisites.
rule_recipes           # Makefile rule recipes.
```
### entrypoint.sh (Optional)
The entrypoint scripts in the container runtime should include a preparation process (such as rendering configuration templates) before executing the container command.
### Dockerfile.j2 (Optional)
A template file for generating a Dockerfile. If container images are not generated using a Dockerfile, this file is not required.
### manifest.yaml (Optional)
A data file used for rendering the Dockerfile. If container images are not generated using a Dockerfile, this file is also not required. 
This file configures how to install online RPMs within a Dockerfile. The process involves two steps: downloading and installing the RPMs.
```
name                      # The name of the RPM.
version                   # The version of the RPM.
url                       # The download URL for the RPM (required if download_command is specified).
download_command          # The command to download the RPM. Supported values: dnf and curl.
download_command_options  # Options for the download command.
install_command           # The command to install the RPM. Supported values: dnf and rpm.
install_command_options   # Options for the install command.
```
## Build
To start the build process, enter the containers directory and run the following command:
```
make YUM_REPO_FILE=/directory/path/yum.conf IMAGE_TAG=v1.0.0
```
- `YUM_REPO_FILE` specifies the path to the YUM repository configuration file.
- `IMAGE_TAG` sets the version tag for the container image.

Once the build is complete, the image tar files will be available in the `build/images` directory.