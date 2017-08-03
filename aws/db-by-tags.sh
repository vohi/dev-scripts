#!/bin/bash
ARNS=$(aws rds describe-db-instances --region eu-west-1 --query "DBInstances[].DBInstanceArn" --output text)
for line in $ARNS; do
    TAGS=$(aws rds list-tags-for-resource --region eu-west-1 --resource-name "$line" --query "TagList[]")
    MATCHES=$(echo $TAGS | python -c "import sys, json; tags = json.loads('$1'); remote = {t['Key']: t['Value'] for t in json.load(sys.stdin)}; print('$line') if len({'$line' for k, v in tags.items() if k in remote and v == remote[k]}) > 0 else ''")
    if [[ ! -z $MATCHES ]]; then
        echo $MATCHES
    fi
done

