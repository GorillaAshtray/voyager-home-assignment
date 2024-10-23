# This 'keep_count' argument later mentioned in the script represents the maximum amount of snapshots that can be stored
# that have the same volume ID, meaning that if, for example the keep_count variable is 3, there can be more than 3 total
# snapshots archived, however there can not be more than 3 snapshots that have the same volume ID 

import boto3
import sys

def create_snapshot(volume_id, snapshot_name):
    ec2 = boto3.client('ec2')

    # Create a new snapshot
    try:
        snapshot = ec2.create_snapshot(VolumeId=volume_id, Description=snapshot_name)
        snapshot_id = snapshot['SnapshotId']
        print(f"Snapshot created with ID: {snapshot_id}")
        return snapshot_id
    except Exception as e:
        print(f"Error creating snapshot: {e}")
        sys.exit(1)

def delete_old_snapshots(volume_id, keep_count):
    ec2 = boto3.client('ec2')

    try:
        # Describe snapshots and filter by volume ID
        snapshots = ec2.describe_snapshots(
            Filters=[{'Name': 'volume-id', 'Values': [volume_id]}]
        )['Snapshots']

        # Sort snapshots by creation time
        snapshots = sorted(snapshots, key=lambda s: s['StartTime'], reverse=False)

        # If there are more snapshots than the 'keep_count', delete the oldest
        if len(snapshots) > keep_count:
            to_delete = snapshots[:len(snapshots) - keep_count]  # Older snapshots to delete
            for snapshot in to_delete:
                snapshot_id = snapshot['SnapshotId']
                ec2.delete_snapshot(SnapshotId=snapshot_id)
                print(f"Deleted snapshot: {snapshot_id}")
        else:
            print(f"No old snapshots to delete. Total snapshots: {len(snapshots)}")
    except Exception as e:
        print(f"Error deleting old snapshots: {e}")
        sys.exit(1)

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python snapshot_ec2.py <snapshot_name> <volume_id> <keep_count>")
        sys.exit(1)

    snapshot_name = sys.argv[1]
    volume_id = sys.argv[2]
    keep_count = int(sys.argv[3])

    # Create a new snapshot
    create_snapshot(volume_id, snapshot_name)

    # Clean up old snapshots
    delete_old_snapshots(volume_id, keep_count)
