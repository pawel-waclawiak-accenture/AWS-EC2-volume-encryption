#!/bin/bash

aws ec2 describe-volumes | jq -c '.Volumes[] 
                                | .VolumeId as $vid 
                                | .State as $state
                                | .Attachments[].InstanceId as $instance
                                | select(.Encrypted == false)
                                | select(.State == "in-use")
                                | [$vid, $instance]' | \
while read line
do
    vid=$(echo ${line} | jq -r '.[0]')
    iid=$(echo ${line} | jq -r '.[1]')
    iname=$(aws ec2 describe-instances --instance-ids ${iid} --query "Reservations[].Instances[].Tags" | jq -r '.[] | .[] | select(.Key=="Name") | .Value')
    echo ${vid} ${iid} ${iname}
done