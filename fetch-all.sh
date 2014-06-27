#!/bin/bash
for dir in */; do
  cd $dir
  echo "Updateing $dir..."
  git gc --aggressive
  git fetch --all
  echo
  cd ..
done
