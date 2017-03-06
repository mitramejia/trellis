#!/bin/bash
shopt -s nullglob

ENVIRONMENTS=( hosts/* )
ENVIRONMENTS=( "${ENVIRONMENTS[@]##*/}" )
NUM_ARGS=2
BRANCH_NAME="$(git symbolic-ref HEAD 2>/dev/null)" ||
BRANCH_NAME="(unnamed branch)"     # detached HEAD
BRANCH_NAME=${BRANCH_NAME##refs/heads/}

show_usage() {
  echo "Usage: deploy <environment> <site name> [options]

<environment> is the environment to deploy to ("staging", "production", etc)
<site name> is the WordPress site to deploy (name defined in "wordpress_sites")
[options] is any number of parameters that will be passed to ansible-playbook

Available environments:
`( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )`

Examples:
  deploy staging example.com
  deploy production example.com
  deploy staging example.com -vv -T 60
"
}

# Get local branch name
local_branch_name(){
    BRANCH_NAME="$(git symbolic-ref HEAD 2>/dev/null)" ||
    BRANCH_NAME="(unnamed branch)"     # detached HEAD
    BRANCH_NAME=${BRANCH_NAME##refs/heads/}
    echo ${BRANCH_NAME}
}

# Returns 0 if local branch is up to date with it's remote counterpart
local_branch_is_up_to_date(){
    UPSTREAM=${1:-'@{u}'}
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse "$UPSTREAM")
    BASE=$(git merge-base @ "$UPSTREAM")

    if [ ${LOCAL} = ${REMOTE} ]; then
        # run deploy command
        echo "Up-to-date"
        return 0

    elif [ ${LOCAL} = ${BASE} ]; then
        echo "Warning: your is not up to date. Enter 'yes' to continue if you know what you're doing or        stop and pull down the latest changes with git pull origin "$(local_branch_name);

    elif [ ${REMOTE} = ${BASE} ]; then
        echo "Maybe you need to push the remote branch and solve conflicts"

    else
        echo "It seems local branch diverges"
    fi
}

<<<<<<< 77f72ffdcf173eb03903e98483ef5e9b13288191
[[ $# -lt 2 ]] && { show_usage; exit 0; }

for arg
do
  [[ $arg = -h ]] && { show_usage; exit 0; }
done
=======

HOSTS_FILE="hosts/$1"
>>>>>>> Add verify branch is up to date function

ENV="$1"; shift
SITE="$1"; shift
EXTRA_PARAMS=$@
DEPLOY_CMD="ansible-playbook deploy.yml -e env=$ENV -e site=$SITE $EXTRA_PARAMS"
HOSTS_FILE="hosts/$ENV"

if [[ ! -e $HOSTS_FILE ]]; then
  echo "Error: $ENV is not a valid environment ($HOSTS_FILE does not exist)."
  echo
  echo "Available environments:"
  ( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )
  exit 0
fi

if [[ $BRANCH_NAME != 'master' ]]
then
  echo -e 'You are not on master branch. Are you sure you want to continue? [y/N]'
  read -r RESPONSE
fi
if [[ $RESPONSE =~ ^([yY][eE][sS]|[yY])$ ]]
  then
    $DEPLOY_CMD
  else
    echo -e 'Aborted'
    exit 0
fi
