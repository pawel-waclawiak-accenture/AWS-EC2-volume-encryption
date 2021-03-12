#!/bin/bash

aws ec2 describe-volumes | jq -r '.Volumes[] | .VolumeId as $vid | .State as $state | select(.Encrypted == false) | select(.State != "in-use") | [$vid, $state] | @csv'
