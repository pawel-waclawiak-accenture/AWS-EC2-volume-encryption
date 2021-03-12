#!/bin/bash

aws ec2 describe-volumes | jq -r '.Volumes[] | .VolumeId as $vid | select(.Encrypted == false) | select(.State == "in-use") | [$vid] | @csv' | wc -l
