#! /bin/bash

set -Eeuxo pipefail

export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Applications/VMware Fusion.app/Contents/Public"

source ~/.profile

echo
echo "Running for $1 at $(date) ($(whoami))"

minicoin list

if ! cd $1
then
    echo "No such path: $1"
    exit 1
fi
shift

build_name=${1}
shift

echo "Updating $PWD from revision $(git log -n 1 --oneline)"
git fetch
git clean -dfx
git rebase
revision=$(git log -n 1 --oneline)
echo "Now on revision: $revision"

revision=$(echo $revision | cut -d' ' -f 1)

export QT_LANCELOT_SERVER=$(dig lancelot.intra.qt.io +short)

machines=$@
report_address=volker.hilsheimer@qt.io

exit_status=0
logfile=~/baseline_logs/qtbase-${revision}
mkdir -p ~/baseline_logs &> /dev/null

echo "Logs will be written to $logfile"

if [[ -z $machines ]]
then
    machines=(
        opensuse15
        ubuntu2004
        windows10
        macos1015
        macos11
        macos12
    )
fi

tests=(
    tst_baseline_widgets
    tst_baseline_stylesheet
    tst_baseline_text
)

function run_tests
{
    cmd="minicoin run --env QT_LANCELOT_SERVER=${QT_LANCELOT_SERVER} build --build ${build_name} --testargs \"-auto\" --target"
    machine=$1
    for test in ${tests[@]}
    do
        echo "Building $test on ${machine} (${build_name})"
        if ! $cmd ${test} ${machine} | tee -a ${logfile}-${machine}-build.log
        then
            >&2 echo "Baseline compile failure on ${machine} (${build_name}), starting clean build"
            if ! $cmd ${test} --clean ${machine} | tee -a ${logfile}-${machine}-build.log
            then
                >&2 echo "Baseline compile failure on ${machine} (${build_name})"
                cat ${logfile}-${machine}-build.log | mail -s "Baseline compile failure on ${machine} (${build_name})" $report_address
                return $?
            fi
        fi

        echo "Running $test on ${machine} (${build_name})"
        if ! $cmd ${test}_check ${machine} | tee -a ${logfile}-${machine}-check.log
        then
            >&2 echo "Baseline test failure on ${machine} (${build_name})"
            cat ${logfile}-${machine}-check.log | mail -s "Baseline test failure on ${machine} (${build_name}), revision ${revision}" $report_address 
            exit_status=1
        fi
    done
}

for machine in ${machines[@]}
do
    echo "Running on $machine"
    halt=1 # always stop machines at the end
    if ! minicoin status $machine | grep "  running" > /dev/null
    then
        halt=1
        if ! minicoin up $machine
        then
            >&2 echo "$machine failed to boot, recreating"
            minicoin destroy -f $machine
            if ! minicoin up $machine
            then
                >&2 echo "$machine failed to boot, skipping"
                echo "Skipping machine when trying to build ${build_name}" | mail -s "Baseline failure, machine $machine failed to boot" $report_address 
                exit_status=1
                continue
            fi
        fi
        minicoin mutagen wait $machine
    fi

    if [[ "$machine" == mac* ]]
    then
        minicoin cmd $machine -- osascript -l JavaScript -e \"Application\(\'System Events\'\).appearancePreferences.darkMode = false\"
    fi

    run_tests $machine

    if [[ "$machine" == mac* ]]
    then
        minicoin cmd $machine -- osascript -l JavaScript -e \"Application\(\'System Events\'\).appearancePreferences.darkMode = true\"
        run_tests $machine 
    fi

    if [ $halt -gt 0 ]
    then
        minicoin halt $machine
    fi
done

if [ $exit_status -eq 0 ]
then
    echo "Baseline run complete on ${machines[@]}" | mail -s "Baseline test successful for $revision (${build_name})" $report_address
else
    cat /tmp/baseline_run.log | mail -s "Baseline test error for $revision (${build_name})" $report_address
fi

echo "Ending at $(date)"
exit $exit_status

