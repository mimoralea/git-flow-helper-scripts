#!/bin/bash
# This script helps you checkout the latest branch or tag of a particular branch type using git flow branching model.
# If you use git branching model, you sometimes need to checkout the latest 'release' branch or latest 'tag' or latest
# hotfix branch. This is the purpose of this script.

usage()
{
    echo "-m    Checkout master branch and pull changes";
    echo "-d    Checkout develop branch and pull changes";
    echo "-r    Checkout the release branch that contains the latest commit";
    echo "-h    Checkout the hotfix branch that contains the latest commit";
    echo "-t    Checkout the latest tag";
    echo "-j    Just Kidding. Dry run. What would happen with the options passed?";
    echo "";
    echo "E.g. usage:";
    echo "";
    echo "checkout-latest.sh -h";
    echo "This would checkout the remote hotfix branch with the latest commit on.";
    echo "";
    echo "checkout-latest.sh -tj";
    echo "This would show which tag would have been checked out if no kidding.";
    echo "";
    exit
}

if [[ $# -eq 0 ]] ; then
    echo "Please pass at least one argument.";
    usage
fi

TYPE=""
BRANCH=""
JUST_KIDDING=false

OPTIND=1         # Reset in case getopts has been used previously in the shell.

while getopts "?mdrhtj" opt; do
    case "$opt" in
	m)  [[ -n "$TYPE" ]] && echo "Please, select only one checkout type." && usage || TYPE='master'
            ;;
	d)  [[ -n "$TYPE" ]] && echo "Please, select only one checkout type." && usage || TYPE='develop'
            ;;
	r)  [[ -n "$TYPE" ]] && echo "Please, select only one checkout type." && usage || TYPE='release'
            ;;
	h)  [[ -n "$TYPE" ]] && echo "Please, select only one checkout type." && usage || TYPE='hotfix'
            ;;
	t)  [[ -n "$TYPE" ]] && echo "Please, select only one checkout type." && usage || TYPE='tag'
            ;;
	j)  JUST_KIDDING=true
            ;;
	\?) usage ;;
	*) usage ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

# this would not get executed, but it might if we add arguments in the future.
if [[ "$TYPE" == "" ]] ; then
    echo "You must select a checkout type."
    usage
fi

# does this get tags as well??? It seems like, but need to verify.
git fetch --all

if [[ "$TYPE" == "tag" ]] ; then
    git fetch --tags
    LATEST_TAG=$(git describe --tags `git rev-list --tags --max-count=1`)
    echo "Checking out the tag: $LATEST_TAG"
    if $JUST_KIDDING ; then
        echo "Just Kidding."
    else
	git checkout "$LATEST_TAG"
    fi
    exit
fi

echo "Latest available branches on remote:"
for k in `git branch -r | perl -pe 's/^..(.*?)( ->.*)?$/\1/'`; do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k -- | head -n 1`\\t$k; done | sort -r

BRANCH=$(for k in `git branch -r | perl -pe 's/^..(.*?)( ->.*)?$/\1/'`; do echo -e `git show --pretty=format:"%Cgreen%ci %Cblue%cr%Creset" $k -- | head -n 1`\\t$k; done | sort -r | awk -F'origin/' '{ print $2 }' | grep $TYPE | head -n 1)

if [[ "$BRANCH" == "" ]] ; then
    echo "Couldn't find a branch of type ($TYPE) defaulting to master."
    BRANCH="master"
fi

echo "Checking out $BRANCH"
    if $JUST_KIDDING ; then
        echo "Just Kidding."
    else
        git checkout "$BRANCH"
        git pull
    fi
exit
