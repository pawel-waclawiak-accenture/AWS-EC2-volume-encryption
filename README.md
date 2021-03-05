# Volume encryption automation

This script's purpose is to streamline the process of volume encryption in AWS as it requires several steps that usually require to wait for a short while to complete. The process itself is pretty straightforward and repetitive so it is a perfect match for a script like this.

## Usage
The main file is `encrypt.sh` it takes care of the whole process.

It requires 4 positional arguments which are as follows: instance id (where the volume is attached), volume id, instance name (for tagging purpose). The fourth one is a `--accept` flag just to prevent accidental script execution provided with incorrect data.
```
./encrypt.sh <instance_id> <volume_id> <instance_name> --accept
```

### Multiple volumes
Sometimes an instance has multiple volumes attached to it. `encrypt.sh` gives the new volume a tag of a `root-volume` and of course it would make no sense to tag multiple volumes with this tag, so that is why there is also `additional_volume_encrypt.sh` script. The only way it differs from `encrypt.sh` is the tag it gives to the volume and in this case it is `secondary-volume` (this could of course be changed to any suitable one).

Usage is the same as with the stangard version, so:
```
./additional_volume_encrypt.sh <instance_id> <volume_id> <instance_name> --accept
```

## Misc
It is worth to mention why there are actually multiple scripts if the same could be done with just one after some manual adjustments. The answer is that you can run multiple instances of terminal and encrypt multiple volumes at once. 

The scripts store some of their operational data in text files, but this is not an issue (unless encrypting 2 volumes on 1 instance at the same time) because they store it in separate directories. Also these files are not being removed after the job is done so it makes some kind of a history log.

## Token expiration
Infact a volume in AWS cannot be encrypted itself. It requires to take a snapshot and recreate an encrypted volume out of it. The main issue with that is to take the snapshot as it can take a long time, even an hour or two sometimes, although CLI token is issued for the maxium time of 1 hour. That is why there is `resume_encryption.sh` script, which is basically the same as `encrypt.sh` just with actions before snapshot taking commented out as this is the most common action to encounter a token expiration. This can of course happen in anoter part of the script, and such situation requires adjustments on the actions which still need to be taken and what have been done already.

Usage is the same as with the other ones:
```
./resume_encryption.sh <instance_id> <volume_id> <instance_name> --accept
```
