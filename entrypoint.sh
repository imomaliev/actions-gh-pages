#!/bin/bash

set -e
# set -ex

function print_error() {
    echo -e "\e[31mERROR: ${1}\e[m"
}

function print_info() {
    echo -e "\e[36mINFO: ${1}\e[m"
}

# check values
if [ -z "${GITHUB_TOKEN}" ]; then
    print_error "not found GITHUB_TOKEN"
    exit 1
fi

if [ -z "${PUBLISH_BRANCH}" ]; then
    print_error "not found PUBLISH_BRANCH"
    exit 1
fi

if [ -z "${PUBLISH_DIR}" ]; then
    print_error "not found PUBLISH_DIR"
    exit 1
fi

remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
remote_branch="${PUBLISH_BRANCH}"

local_dir="${HOME}/$(tr -cd 'a-f0-9' < /dev/urandom | head -c 32)"
if git clone --depth=1 --single-branch --branch "${remote_branch}" "${remote_repo}" "${local_dir}"; then
    cd "${local_dir}"
    git rm -r '*'
    find "${GITHUB_WORKSPACE}/${PUBLISH_DIR}" -maxdepth 1 | \
        tail -n +2 | \
        xargs -I % cp -rf % "${local_dir}/"
else
    cd "${PUBLISH_DIR}"
    git init
    git checkout --orphan "${remote_branch}"
fi

# push to publishing branch
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git remote rm origin || true
git remote add origin "${remote_repo}"
git add --all
git commit --allow-empty -m "Automated deployment: $(date -u) ${GITHUB_SHA}"
git push origin "${remote_branch}"
print_info "${GITHUB_SHA} was successfully deployed"