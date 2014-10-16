#!/bin/bash
# This script is intended to manage the version of a project using the git flow branching model.
# If you have a file in your project that keeps track of your apps version, but also have git keeping 
# versions, tags and such. This script can help you by quickly modifying you version's file 
# depending on the type of branch you are creating. You could even add a git hook!

usage()
{
    echo "-v    Shows current full version";
    echo "-m    Major bump. Increases the major version";
    echo "-r    Release bump. Increases the release version";
    echo "-h    Hotfix bump. Increases the hotfix version";
    echo "-d    Dry run. What would happen with the options passed?";
    echo "-c    Commit \"Bumping version on (major|release|hotfix) to vX.X.X\" - will clear the staging area.";
    echo "-p    Publish the branch. (hotfix|release) if a major bump, it uses release for the branch. It assumes you already created a local branch with the version you are bumping to.";
    echo "";
    echo "E.g. usage:";
    echo "";
    echo "bump.sh -hcp";
    echo "This would bump the hotfix number, commit the changes and publish the new hotfix branch.";
    echo "";
    echo "bump.sh -rp";
    echo "This would bump the release number and publish the new release branch.";
    echo "";
    echo "bump.sh -mp";
    echo "This would bump the major number and publish the new release branch.";
    echo "";
    echo "";
    echo "Bump schema: v<m>.<r>.<h>";
    echo "";
    echo "-m: 2.3.4 -> 3.0.0";
    echo "-r: 2.3.4 -> 2.4.0";
    echo "-h: 2.3.4 -> 2.3.5";

    exit
}

if [[ $# -eq 0 ]] ; then
    echo "Please pass at least one argument.";
    usage
fi

TYPE=""
DRY=false
COMMIT=false
PUBLISH=false
# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

# Initialize our variables:
PROJECT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."; # USE THIS TO GET TO THE ROOT OF YOUR PROJECT RELATIVE TO WHERE YOU PLACE THIS SCRIPT
VERSION_FILE_PATH="$PROJECT_PATH/app/configs/version.yml";  # THIS SHOULD BE THE PATH TO THE FILE WHERE YOU SAVE YOUR APP VERSION
APP_VERSION="`sed -n '/app_version/p' "$VERSION_FILE_PATH" | awk -F' ' '{print $2}'`"; # USE THIS TO EXTRACT YOUR CURRENT VERSION NUMBER


while getopts "?vmrhdcp" opt; do
    case "$opt" in
    d)  DRY=true ;;
    c)  COMMIT=true ;;
    p)  PUBLISH=true ;;
    v)  echo Current: v$APP_VERSION; # for display prepend the vX.X.X
        exit
        ;;
    m)  [[ -n "$TYPE" ]] && echo "Please, select only one bump type. (m|r|h)" && usage || TYPE='major'
        MAJOR=$(printf '%s\n' $APP_VERSION | awk -F'.' '{print $1}' | awk -F' ' '{$NF = $NF + 1;} 1')       # get the major version and increase it
        RELEASE="0"                                                                                         # reset the release
        HOTFIX="0"                                                                                          # reset the hotfix
        ;;
    r)  [[ -n "$TYPE" ]] && echo "Please, select only one bump type. (m|r|h)" && usage || TYPE='release'
        MAJOR=$(printf '%s\n' $APP_VERSION | awk -F'.' '{print $1}')                                       # get the major version
        RELEASE=$(printf '%s\n' $APP_VERSION | awk -F'.' '{print $2}' | awk -F' ' '{$NF = $NF + 1;} 1')    # get the release and increase it
        HOTFIX="0"  
        ;;
    h)  [[ -n "$TYPE" ]] && echo "Please, select only one bump type. (m|r|h)" && usage || TYPE='hotfix'
        MAJOR=$(printf '%s\n' $APP_VERSION | awk -F'.' '{print $1}')                                       # get the major version
        RELEASE=$(printf '%s\n' $APP_VERSION | awk -F'.' '{print $2}')                                     # get the release and increase it
        HOTFIX=$(printf '%s\n' $APP_VERSION | awk -F'.' '{print $3}' | awk -F' ' '{$NF = $NF + 1;} 1')     # get the hotfix and increase it
        ;;
    \?) usage ;;
    *) usage ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

if [[ "$TYPE" == "" ]] ; then
    echo "You must select a bump type. Major -m, Release -r or Hotfix -h. For help -?"
    exit
fi


NEW_VERSION="$MAJOR.$RELEASE.$HOTFIX"                                                           # set it up back in order
if $DRY ; then                                                                                  # if dry run
    echo "Version would have been changed to v$NEW_VERSION."                                     # print and
    if $COMMIT ; then
        echo "Commit would have been created with the message \"Bumping version on $TYPE to $NEW_VERSION.\"."
    fi

    if [[ "$TYPE" == "major" ]] ; then
        TYPE="release"
    fi

    if $PUBLISH ; then
        echo "The $TYPE branch $NEW_VERSION would have been published."
    fi
    exit                                                                                        # get out
fi

SAFE_CURRENT=$(printf '%s\n' "$APP_VERSION" | sed 's/[[\.*^$/]/\\&/g')                         # escape the periods (.)
SAFE_NEW=$(printf '%s\n' "$NEW_VERSION" | sed 's/[[\.*^$/]/\\&/g')                              # escape the periods (.)
# USE THIS INSTEAD OF SED SINCE MAC AND LINUX HAVE DIFFERENT VERSIONS AND THE REPLACE IN PLACE COMMAND FAILS IN ONE OR THE OTHER
perl -pi -e "s,$SAFE_CURRENT,$SAFE_NEW,g" "$PARAMETERS_PATH"                                    # replace the value on the expected file
### ACTUAL REPLACEMENT
echo Changed to: v"$NEW_VERSION"

if $COMMIT ; then                                                                               # if commit
    git reset HEAD . > /dev/null
    git add $PARAMETERS_PATH > /dev/null
    git commit -m "Bumping version on $TYPE to $NEW_VERSION."
fi

if [[ "$TYPE" == "major" ]] ; then
    TYPE="release"
fi

if $PUBLISH ; then                                                                               # if commit
    git push -u origin $TYPE/$NEW_VERSION > /dev/null
fi

