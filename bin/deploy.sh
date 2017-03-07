#!/bin/bash

# 1. Check if environment exists. If not exit the script
# 2. Check if current branch is master. If not display warning and prompt a confirmation message
# 3. Check if current branch is upt to date. If not display warning and prompt a confirmation message
# If all of the above are true run the deploy command

shopt -s nullglob

ENVIRONMENTS=( hosts/* )
ENVIRONMENTS=( "${ENVIRONMENTS[@]##*/}" )


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

# Get current local branch name
local_branch_name(){
    local BRANCH_NAME="$(git symbolic-ref HEAD 2>/dev/null)" ||
    local BRANCH_NAME="(unnamed branch)"     # detached HEAD
    local BRANCH_NAME=${BRANCH_NAME##refs/heads/}
    echo ${BRANCH_NAME}
}

# Check if current local branch is up to date with it's remote counterpart
branch_is_up_to_date(){
    local UPSTREAM=${1:-'@{u}'}
    local LOCAL=$(git rev-parse @)
    local REMOTE=$(git rev-parse "$UPSTREAM")
    local BASE=$(git merge-base @ "$UPSTREAM")

    if [ ${LOCAL} = ${REMOTE} ]; then
        return 0
    else
        return 1
    fi
}


[[ $# -lt 2 ]] && { show_usage; exit 0; }

for arg
do
  [[ $arg = -h ]] && { show_usage; exit 0; }
done

ENV="$1"; shift
SITE="$1"; shift
EXTRA_PARAMS=$@
DEPLOY_CMD="ansible-playbook deploy.yml -e env=$ENV -e site=$SITE $EXTRA_PARAMS"
HOSTS_FILE="hosts/$ENV"

# Check if inserted environment exists
if [[ ! -e ${HOSTS_FILE} ]]; then
  echo "Error: $ENV is not a valid environment ($HOSTS_FILE does not exist)."
  echo
  echo "Available environments:"
  ( IFS=$'\n'; echo "${ENVIRONMENTS[*]}" )
  exit 0
fi

# Ask for confirmation if current local branch is not master
if [[ local_branch_name != 'master' ]]; then
  read -p "Warning: you are deploying from when the site is set to . Enter 'yes' to continue if you know what you're doing." RESPONSE

  if [[ ${RESPONSE} =~ ^([yY][eE][sS]|[yY])$ ]]; then
    ${DEPLOY_CMD}
  fi

# Ask for confirmation if current branch is up to date with it's remote counterpart
elif [[ !branch_is_up_to_date ]]; then
      read -p "Warning: your branch is not up to date. Enter 'yes' to continue if you know what you're doing or stop and pull down the latest changes with git pull origin " $(local_branch_name) RESPONSE
    if [[ ${RESPONSE} =~ ^([yY][eE][sS]|[yY])$ ]]; then
      ${DEPLOY_CMD}
    fi

#if everything is ok. Run the deploy script
else
    ${DEPLOY_CMD}
fi


