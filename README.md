git-flow-helper-scripts
=======================

Scripts to assist with git flow branching model


###bump.sh
This script is intended to manage the version of a project using the git flow branching model.
If you have a file in your project that keeps track of your apps version, but also have git keeping 
versions, tags and such. This script can help you by quickly modifying you version's file 
depending on the type of branch you are creating. You could even add a git hook!

###checkout-latest.sh
This script helps you checkout the latest branch or tag of a particular branch type using git flow branching model.
If you use git branching model, you sometimes need to checkout the latest 'release' branch or latest 'tag' or latest
hotfix branch. This is the purpose of this script.
