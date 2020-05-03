#!/bin/sh

## decide runner type
case "${GHAR_TYPE}" in
    org|ORG)
        if [ -z "${GHAR_OWNER}" ]; then
            echo "Error! GHAR_OWNER is not defined."
            exit 1
        else
            if [ ! -z "${GHAR_REPOSITORY}" ]; then
            echo "Info! GHAR_TYPE: ${GHAR_TYPE} is set. GHAR_REPOSITORY: ${GHAR_REPOSITORY} will be omitted."
            fi
            echo "Info! Registering orgnization specific runner for ${GHAR_OWNER}."
        fi
        registration_url="https://api.github.com/orgs/${GHAR_OWNER}/actions/runners/registration-token"
        GHAR_CONFIG_URL="https://github.com/${GHAR_OWNER}"
    ;;

    repo|REPO)
        if [ -z "${GHAR_OWNER}" ];  then
            echo "Error! GHAR_OWNER is not defined."
            exit 1
        elif [ -z "${GHAR_REPOSITORY}" ]; then
            echo "Errot! GHAR_REPOSITORY is not defined. Must be defined for GHAR_TYPE: ${GHAR_TYPE}."
            exit 1
        else
            echo "Info! Registering repository specific runner for ${GHAR_REPOSITORY}."
        fi
        registration_url="https://api.github.com/repos/${GHAR_OWNER}/${GHAR_REPOSITORY}/actions/runners/registration-token"
        GHAR_CONFIG_URL="https://github.com/${GHAR_OWNER}/${GHAR_REPOSITORY}"
    ;;

    *)
        echo "Warn! GHAR_TYPE not defined."

        if [ -z "${GHAR_OWNER}" ] && [ -z "${GHAR_REPOSITORY}" ]; then
            echo "Error! GHAR_OWNER & GHAR_REPOSITORY not defined."
            exit 1
        elif [ ! -z "${GHAR_OWNER}" ] && [ ! -z "${GHAR_REPOSITORY}" ]; then
            echo "Info! Registering repository specific runner for ${GHAR_REPOSITORY}."
            registration_url="https://api.github.com/repos/${GHAR_OWNER}/${GHAR_REPOSITORY}/actions/runners/registration-token"
            GHAR_CONFIG_URL="https://github.com/${GHAR_OWNER}/${GHAR_REPOSITORY}"
        elif [ ! -z "${GHAR_OWNER}" ]; then
            echo "Info! Registering orgnization specific runner for ${GHAR_OWNER}."
            registration_url="https://api.github.com/orgs/${GHAR_OWNER}/actions/runners/registration-token"
            GHAR_CONFIG_URL="https://github.com/${GHAR_OWNER}"
        else
            echo "Error! GHAR target owner/repository not defined."
            exit 1
        fi
esac
    
echo "Requesting GHAR registration URL at '${registration_url}'"

## hack: run the runner as root
export RUNNER_ALLOW_RUNASROOT=1

## add github key to known_hosts
ssh-keyscan -t rsa -H github.com >> /.ssh/known_hosts

## start docker service
sudo service docker status
sudo service docker start
sudo service docker status

## register runner based on type
payload=$(curl -sX POST -H "Authorization: token ${GITHUB_PAT}" ${registration_url})
export GHAR_TOKEN=$(echo $payload | jq .token --raw-output)

./config.sh \
    --name $(hostname) \
    --token ${GHAR_TOKEN} \
    --url ${GHAR_CONFIG_URL} \
    --work ${RUNNER_WORKDIR} \
    --unattended \
    --replace

remove() {
    ./config.sh remove --unattended --token "${GHAR_TOKEN}"
}

trap 'remove; exit 130' INT
trap 'remove; exit 143' TERM

## hack: do not restart container on upgrade
./bin/runsvc.sh "$*" &

wait $!