#!/bin/bash

RUN_GC=true
case "$1" in
  --fast)
    RUN_GC=false
esac

for dir in */; do
  cd $dir
  echo "Updateing $dir..."
  if $RUN_GC
  then
    git gc --aggressive
  fi
  git fetch --all
  echo
  cd ..
done
