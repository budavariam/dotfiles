#!/bin/bash

# Projects
alias cs="cd ~/project"
alias howto="code ~/project/todolog"
alias dotfiles="code ~/project/dotfiles"

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# Update/reload bash_profile
alias bashreload="source ~/.bash_profile"

# Open the last command with authority
alias please='sudo $(fc -ln -1)'


# Docker aliases (https://github.com/Bash-it/bash-it)
alias dklc='docker ps -l'  # List last Docker container
alias dklcid='docker ps -l -q'  # List last Docker container ID
alias dklcip='docker inspect -f "{{.NetworkSettings.IPAddress}}" $(docker ps -l -q)'  # Get IP of last Docker container
alias dkps='docker ps'  # List running Docker containers
alias dkpsa='docker ps -a'  # List all Docker containers
alias dki='docker images'  # List Docker images
alias dkrmac='docker rm $(docker ps -a -q)'  # Delete all Docker containers
alias dkrmlc='docker-remove-most-recent-container'  # Delete most recent (i.e., last) Docker container

case $OSTYPE in
  darwin*|*bsd*|*BSD*)
    alias dkrmui='docker images -q -f dangling=true | xargs docker rmi'  # Delete all untagged Docker images
    ;;
  *)
    alias dkrmui='docker images -q -f dangling=true | xargs -r docker rmi'  # Delete all untagged Docker images
    ;;
esac

alias dkrmall='docker-remove-stale-assets'  # Delete all untagged images and exited containers
alias dkrmli='docker-remove-most-recent-image'  # Delete most recent (i.e., last) Docker image
alias dkrmi='docker-remove-images'  # Delete images for supplied IDs or all if no IDs are passed as arguments
alias dkideps='docker-image-dependencies'  # Output a graph of image dependencies using Graphiz
alias dkre='docker-runtime-environment'  # List environmental variables of the supplied image ID
alias dkelc='docker exec -it `dklcid` bash' # Enter last container (works with Docker 1.3 and above)

# Docker-compose (https://github.com/Bash-it/bash-it)
alias dco="docker-compose"
alias dcofresh="docker-compose-fresh"
alias dcol="docker-compose logs -f --tail 100"

# Docker helper aliases (https://github.com/Bash-it/bash-it)
function docker-remove-most-recent-container() {
  #about 'attempt to remove the most recent container from docker ps -a'
  #group 'docker'
  docker ps -ql | xargs docker rm
}

function docker-remove-most-recent-image() {
  #about 'attempt to remove the most recent image from docker images'
  #group 'docker'
  docker images -q | head -1 | xargs docker rmi
}

function docker-remove-stale-assets() {
  #about 'attempt to remove exited containers and dangling images'
  #group 'docker'
  docker ps --filter status=exited -q | xargs docker rm --volumes
  docker images --filter dangling=true -q | xargs docker rmi
}

function docker-enter() {
  #about 'enter the specified docker container using bash'
  #group 'docker'
  #param '1: Name of the container to enter'
  #example 'docker-enter oracle-xe'

  docker exec -it "$@" /bin/bash;
}

function docker-remove-images() {
  #about 'attempt to remove images with supplied tags or all if no tags are supplied'
  #group 'docker'
  if [ -z "$1" ]; then
    docker rmi $(docker images -q)
  else
    DOCKER_IMAGES=""
    for IMAGE_ID in $@; do DOCKER_IMAGES="$DOCKER_IMAGES\|$IMAGE_ID"; done
    # Find the image IDs for the supplied tags
    ID_ARRAY=($(docker images | grep "${DOCKER_IMAGES:2}" | awk {'print $3'}))
    # Strip out duplicate IDs before attempting to remove the image(s)
    docker rmi $(echo ${ID_ARRAY[@]} | tr ' ' '\n' | sort -u | tr '\n' ' ')
 fi
}

function docker-image-dependencies() {
  #about 'attempt to create a Graphiz image of the supplied image ID dependencies'
  #group 'docker'
  if hash dot 2>/dev/null; then
    OUT=$(mktemp -t docker-viz-XXXX.png)
    docker images -viz | dot -Tpng > $OUT
    case $OSTYPE in
      linux*)
        xdg-open $OUT
        ;;
      darwin*)
        open $OUT
        ;;
    esac
  else
    >&2 echo "Can't show dependencies; Graphiz is not installed"
  fi
}

function docker-runtime-environment() {
  #about 'attempt to list the environmental variables of the supplied image ID'
  #group 'docker'
  docker run "$@" env
}

function docker-archive-content() {
  #about 'show the content of the provided Docker image archive'
  #group 'docker'
  #param '1: image archive name'
  #example 'docker-archive-content images.tar.gz'

  if [ -n "$1" ]; then
    tar -xzOf $1 manifest.json | jq '[.[] | .RepoTags] | add'
  fi
}

function docker-compose-fresh() {
  #about 'Shut down, remove and start again the docker-compose setup, then tail the logs'
  #group 'docker-compose'
  #param '1: name of the docker-compose.yaml file to use (optional). Default: docker-compose.yaml'
  #example 'docker-compose-fresh docker-compose-foo.yaml'

  local DCO_FILE_PARAM=""
  if [ -n "$1" ]; then
    echo "Using docker-compose file: $1"
    DCO_FILE_PARAM="--file $1"
  fi

  docker-compose $DCO_FILE_PARAM stop
  docker-compose $DCO_FILE_PARAM rm -f
  docker-compose $DCO_FILE_PARAM up -d
  docker-compose $DCO_FILE_PARAM logs -f --tail 100
}
