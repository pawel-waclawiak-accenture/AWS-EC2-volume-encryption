#!/bin/bash

aws ec2 describe-volumes | jq -r '.Volumes[] | .VolumeId as $vid | .State as $state | .Attachments[].InstanceId as $instance | select(.Encrypted == false) | select(.State == "in-use") | [$vid, $instance, $state] | @csv'
