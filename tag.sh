#!/bin/sh

if [ $# -lt 3 ]
then
   echo "Usage: tag BRANCH TAG COMMENT"
   exit
fi

echo "Setting tag $2 with comment $3 at head of branch $1"

(
    echo core
    echo nova
    echo enterprise
    echo mission-portal
    echo autobuild
    echo masterfiles
    echo design-center
    echo system-testing
) | while read repo
do
   echo $repo
   cd $repo
   git tag -d $2
   git checkout $1
   git merge upstream/$1
   git tag -a $2 -m "$3"
   cd ..
done

