#!/bin/bash

docker-ip() {
        boot2docker ip 2> /dev/null
}

redirect-docker-port(){
    for i in {49000..49900}; do
        VBoxManage modifyvm "boot2docker-vm" --natpf1 "tcp-port$i,tcp,,$i,,$i";
        VBoxManage modifyvm "boot2docker-vm" --natpf1 "udp-port$i,udp,,$i,,$i";
    done
}
add-user-dir-to-docker()
{
    #> curl http://static.dockerfiles.io/boot2docker-v1.2.0-virtualbox-guest-additions-v4.3.14.iso > ~/.boot2docker/boot2docker.iso
    VBoxManage sharedfolder add boot2docker-vm -name home -hostpath /Users
}

#echo $(docker-ip) dockerhost | sudo tee -a /etc/hosts
export DOCKER_HOST=tcp://192.168.59.103:2375
