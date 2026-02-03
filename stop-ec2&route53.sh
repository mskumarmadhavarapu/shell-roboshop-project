#!/bin/bash
set -euo pipefail

AWS_REGION="us-east-1"

echo "=== Terminating running EC2 instances in region: $AWS_REGION ==="

INSTANCE_IDS=$(aws ec2 describe-instances \
  --region "$AWS_REGION" \
  --filters Name=instance-state-name,Values=running \
  --query "Reservations[].Instances[].InstanceId" \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "No running EC2 instances found."
else
  echo "Terminating instances: $INSTANCE_IDS"
  aws ec2 terminate-instances \
    --region "$AWS_REGION" \
    --instance-ids $INSTANCE_IDS
fi

echo
echo "=== Cleaning Route53 records (excluding SOA & NS) ==="

HOSTED_ZONES=$(aws route53 list-hosted-zones \
  --query "HostedZones[].Id" \
  --output text)

for ZONE_ID in $HOSTED_ZONES; do
  echo "Processing hosted zone: $ZONE_ID"

  RECORDS=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[?Type!='SOA' && Type!='NS']" \
    --output json)

  if [ "$(echo "$RECORDS" | jq length)" -eq 0 ]; then
    echo "  No deletable records found."
    continue
  fi

  CHANGE_BATCH=$(echo "$RECORDS" | jq '{Changes: map({Action:"DELETE", ResourceRecordSet:.})}')

  aws route53 change-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --change-batch "$CHANGE_BATCH"

  echo "  Deleted non-SOA/NS records."
done

echo
echo "=== Done ==="
