sha=$1
branch=$(git branch --show-current --no-color)
remote="origin"

if [ -z "$1" ]
then
    sha=$branch
fi

remote=$(git remote | grep $remote)

if [ -z "$remote" ]
then
    remote="gerrit"
fi

count=$(git rev-list --count $remote/$branch...$branch)
error=0

if [ "$count" -gt 1 ]
then
  git checkout $remote/$branch 2> /dev/null
  git cherry-pick $sha
  error=$?
fi

if [ "$error" -eq 0 ]
then
  git push gerrit HEAD:refs/for/$branch
fi

git switch - 2> /dev/null
