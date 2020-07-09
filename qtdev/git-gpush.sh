sha="$*"
branch=$(git branch --show-current --no-color)
remote="origin"
repository=$(git worktree list | head -n 1 | awk '{print $1}')

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
  cd $repository
  git checkout $remote/$branch 2> /dev/null
  git cherry-pick $sha
  error=$?
fi

if [ "$error" -eq 0 ]
then
  echo "Pushing..."
  git log --oneline $remote/$branch...
  git push gerrit HEAD:refs/for/$branch
fi
