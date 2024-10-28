# Container Guide
## Description
The directories for generate helmchart packages manifest files. There are many directories, with each one corresponding to a specific job. One job can depend on another job.
## Structure
The job structure of Container is as follows:
```
dirs/
    files/
    templates/
    build.mk
```
### files/
Contains files used with the copy resource.
### templates/
Contains files used with the template resource.
### build.mk
The `build.mk` file is included by the top-level Makefile in the `helmcharts` directory for builds. `build.mk` defines `Makefile rules`, which generate both `file targets`(build/{{rule_name}}/build.done) and `phony targets`. This file supports the following variables, allowing you to set these variables to modify the content of the Makefile rules.
```
rule_name              # Makefile rule name.
rule_prerequisites:    # Makefile rule prerequisites.
rule_recipes           # Makefile rule recipes.
```
## Build
To start the build process, enter the `helmcharts` directory and run the following command:
```
make VERSION=v1.0.0 APP_VERSION=v2.0.0
```
- `VERSION` sets the `version` field in helmchart package.
- `APP_VERSION` sets the `appVersion` field in helmchart package.

Once the build is complete, the helmcharts package files will be found in the `build/helmcharts` directory and the manifest files will be found in the `build/manifests` directory.