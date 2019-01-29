#!/bin/bash

#Dynamically set uid/gid (Openshift needs this)
# See: https://blog.openshift.com/jupyter-on-openshift-part-6-running-as-an-assigned-user-id/
if [[ $UID -ge 10000 ]]; then
    GID=$(id -g)
    sed -e "s/^jetty:x:[^:]*:[^:]*:/jetty:x:$UID:$GID:/" /etc/passwd > /tmp/passwd
    cat /tmp/passwd > /etc/passwd
    rm /tmp/passwd
fi

# Start Jetty
java -jar /usr/local/jetty/start.jar
