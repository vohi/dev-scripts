if [ $# == 0 ]
then
    git commit --amend -a
    exit $?
fi

sha=$1
branch=$(git branch --show-current --no-color)

status=$(git status -s)
if [ ! -z status ]
then
  git stash
fi

git checkout -b temp origin/$branch 2> /dev/null
git cherry-pick $sha
error=$?

if [ $error != 0 ];
then
    git switch -
    git branch -D temp
    exit $error
fi

if [ ! -z status ]
then
    git stash pop
fi

git commit -a --amend
error=$?

git switch -

if [ $error == 0 ]
then
    git rebase temp
    git rebase --skip 2> /dev/null
fi

git branch -D temp