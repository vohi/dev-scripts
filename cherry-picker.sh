#!/bin/sh

CURRENT_BRANCH=$(git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')

if [ "$#" -gt 0 ];
then
    STARTPOINT=$1
else
    STARTPOINT="$CURRENT_BRANCH"-branchpoint
fi

if [ "$#" -gt 1 ];
then
    ENDPOINT=$2
else
    ENDPOINT=master
fi

echo "$STARTPOINT...$ENDPOINT"

UPSTREAM_COMMITS=$(git rev-list --no-merges --reverse $STARTPOINT...$ENDPOINT)

for COMMIT in $UPSTREAM_COMMITS;
do
   IGNORE=$(grep $COMMIT ~/.cherry-picker-blacklist)
   if [ $? -eq 0 ]
   then
      echo "$COMMIT is ignored"
      continue
   fi
   CP_COMMIT=$(git log --grep $COMMIT | wc -l)
   BRANCHES_WITH_COMMIT=$(git branch --contains $COMMIT | grep $CURRENT_BRANCH | wc -l)
   if [ "$CP_COMMIT" -eq 0 ] && [ "$BRANCHES_WITH_COMMIT" -eq 0 ];
   then 
      echo "$COMMIT is not in $CURRENT_BRANCH"
      git show $COMMIT
      CHERRY=$(git cherry $CURRENT_BRANCH master | grep $COMMIT)
      if [ "$CHERRY" = "- $COMMIT" ]
      then
          echo "git cherry has found an equivalent commit in $CURRENT_BRANCH"
      else
          echo "git cherry suggest that this commit should be picked"
          TEST_CHERRY=$(git checkout -b tmp/cherry-picker)
          TEST_CHERRY=$(git cherry-pick --allow-empty -x $COMMIT)
          if [ $? -eq 0 ]
          then
              echo "and can do so without conflicts"
          else
              echo "but has run into merge conflicts - resolve manually and skip this commit to proceed"
          fi
          TEST_CHERRY=$(git reset --hard)
          TEST_CHERRY=$(git checkout $CURRENT_BRANCH)
          TEST_CHERRY=$(git branch -D tmp/cherry-picker)
      fi
      printf "Cherry-pick? [y/n/i/q]: "
      read yesno
      case "$yesno" in
      y)
          git cherry-pick --allow-empty -x $COMMIT
          if [ $? -ne 0 ];
          then
             echo "Cherry-picking failed, aborting"
             exit 1
          fi
          ;;
      i)
          echo "Ignoring $COMMIT from now on..."
          echo "$COMMIT" >> ~/.cherry-picker-blacklist
          ;;
      q)
          echo "Exiting"
          exit 0
          ;;
      *)
          ;;
      esac
   fi
done

