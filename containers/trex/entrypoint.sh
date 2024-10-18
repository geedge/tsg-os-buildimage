#!/bin/sh -ex
chmod +x /opt/tsg/trex/generate-trex-conf.sh
echo 'export PATH=$PATH:/opt/tsg/trex-helper' >> ~/.bashrc
echo 'eval "$(register-python-argcomplete trex-helper)"' >> ~/.bashrc
source ~/.bashrc
/opt/tsg/trex/generate-trex-conf.sh
while true; do sleep 1024;done