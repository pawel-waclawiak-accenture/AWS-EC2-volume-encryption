instance_id=$1
old_volume_id=$2
instance_name=$(echo $3 | tr _ -)
control=$4
timeout_message="Max attempts exceeded"
token_expired="Request has expired."
unauthorized="You are not authorized to perform this operation."
path="instances/"$instance_id

if [ $# -lt 3 ]
then
	echo "You need to provide 3 arguments in this order: instance_id, volume_id, instance_name."
	exit 1
fi

if [ "$control" != "--accept" ]
then
	echo "If you are sure of the variables - instance_id, volume_id, instance_name, then pass '--accept' as the fourth argument. Please check them twice."
	exit 1
fi

await_confirm () {
	while true
	do
		echo $command
		error_message=$($command 2>&1)
		exit_code=$?

		if [ $exit_code -eq 0 ]; then
			break;
		elif [ $exit_code -eq 255 ]; then
			if [[ $error_message == *$timeout_message* ]]; then
				continue
			else
				if [[ $error_message == *$token_expired* ]] || [[ $error_message == *$unauthorized* ]]; then
					echo "Your connection to AWS API has been terminated. Please establish a new one."
				fi
				exit 255
			fi
		else
			echo "Some unexpected error occured. Exiting the script..."
			exit $exit_code
		fi
	done
}

_alarm() {
  length=$(bc -l <<<"${2}/1000")
  ( \speaker-test --frequency $1 --test sine ) > /dev/null&
  pid=$!
  \sleep ${length}s
  \kill -9 $pid
}

mkdir -p $path
# aws ec2 stop-instances --instance-ids $instance_id

# command="aws ec2 wait instance-stopped --instance-ids $instance_id"
# await_confirm $command

# aws ec2 describe-instances --query "Reservations[].Instances[].[Placement.AvailabilityZone,BlockDeviceMappings[*].[DeviceName,Ebs.VolumeId]]" --output text --instance-ids $instance_id | tee >(head -1 > $path/availability_zone) >(grep $old_volume_id | cut -f1 > $path/mounting_point)
availability_zone=$(cat $path/availability_zone)
mounting_point=$(cat $path/mounting_point)



# aws ec2 create-snapshot --volume-id $old_volume_id | tee >(jq -r '.SnapshotId' > $path/snapshot_id)
snapshot_id=$(cat $path/snapshot_id)

command="aws ec2 wait snapshot-completed --snapshot-ids $snapshot_id" 
await_confirm $command



aws ec2 create-volume --availability-zone $availability_zone --tag-specifications "ResourceType=volume,Tags=[{Key=instance,Value=$instance_id},{Key=device,Value=$mounting_point},{Key=Name,Value=$instance_name-root-volume}]" --snapshot-id $snapshot_id | tee >(jq -r '.VolumeId' > $path/new_volume_id)
new_volume_id=$(cat $path/new_volume_id)

command="aws ec2 wait volume-available --volume-ids $new_volume_id"
await_confirm $command



aws ec2 detach-volume --volume-id $old_volume_id

command="aws ec2 wait volume-available --volume-ids $old_volume_id"
await_confirm $command



aws ec2 attach-volume --device $mounting_point --instance-id $instance_id --volume-id $new_volume_id

command="aws ec2 wait volume-in-use --volume-ids $new_volume_id"
await_confirm $command



aws ec2 start-instances --instance-ids $instance_id

command="aws ec2 wait instance-running --instance-ids $instance_id"
await_confirm $command



echo "Data to fill in the excel spreadsheet:"
echo "InstanceId: $instance_id"
echo "SnapshotId: $snapshot_id"
echo -e "VolumeId: $new_volume_id\n"

_alarm 800 500 && sleep .5 && _alarm 800 500 && sleep .55 && _alarm 800 800