#!/bin/bash

RUN_GC=false
RUN_PRUNE=false
MERGE_FF=false
PRINT_HELP=false

while [[ $# > 1 ]]
do

case "$1" in
  --gc)
    RUN_GC=true
    ;;

  -f|--full)
    RUN_GC=true
    RUN_PRUNE=true
    ;;

  --prune)
    RUN_PRUNE=true
    ;;

  -m|--merge)
    MERGE_FF=true
    shift
    LOCAL_BRANCH=$1
    shift
    REMOTE_BRANCH=$1
    ;;

  *)
    PRINT_HELP=true
    ;;
esac

shift
echo "first arg is now: $1"
done

if $PRINT_HELP
then
   echo "For all subdirectories, fetch all remotes"
   echo "Options:"
   echo "  -m, --merge LOCAL REMOTE: merge REMOTE into LOCAL (fast-forward only)"
   echo "  --gc              : run git garbage collection"
   echo "  --prune           : run git pruning"
   echo "  -f, --full        : both gc and prune"
   exit 0
fi

for dir in */; do
  cd $dir
  echo "Updateing $dir..."
  if $RUN_GC
  then
    git gc --aggressive
  fi
  if $RUN_PRUNE
  then
    git prune
  fi
  git fetch --all
  if $MERGE_FF
  then
    git checkout $LOCAL_BRANCH
    git merge $REMOTE_BRANCH --ff-only
  fi
  echo
  cd ..
done
