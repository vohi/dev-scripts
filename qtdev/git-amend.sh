if [ $# == 0 ]
then
    git commit --amend
    exit $?
fi

sha=$1
branch=$(git branch --show-current --no-color)

  stashsha="$(git stash create)"
if [ ! -z stashsha ]
then
    git stash store
    git reset --hard
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

if [ ! -z stashsha ]
then
    git stash pop
fi

git commit --amend
error=$?

git switch -

if [ $error == 0 ]
then
    git rebase temp
    git rebase --skip 2> /dev/null
fi

git branch -D temp