#!/bin/bash
##
#  Copyright (c) DataStax, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
##

#Debug statements [if needed]
#set -x #Trace
#set -n #Check Syntax
set -e #Fail fast on non-zero exit status

WORKER_INFORMATION=($(echo ${OS_VERSION} | tr "/" " "))
OS_NAME=${WORKER_INFORMATION[0]}
RELEASE=${WORKER_INFORMATION[1]}
PROCS=$(grep -e '^processor' -c /proc/cpuinfo)

if [ "${OS_NAME}" = "centos" ]; then
  TOKENS=($(echo ${RELEASE} | tr "-" " "))
  RELEASE=${TOKENS[0]}
  if [ ${RELEASE} -lt 6 ] || [ ${RELEASE} -gt 7 ]; then
    printf "Invalid CentOS/RHEL release '${OS_VERSION}'\n"
    exit 1
  fi
elif [ "${OS_NAME}" = "ubuntu" ]; then
  if [ "${RELEASE}" = "trusty64" ]; then
    RELEASE=14.04
  elif [ "${RELEASE}" = "xenial64" ]; then
    RELEASE=16.04
  elif [ "${RELEASE}" = "bionic64" ]; then
    RELEASE=18.04
  else
    printf "Invalid Ubuntu release '${OS_VERSION}'\n"
    exit 1
  fi
else
  printf "Invalid operating system '${OS_VERSION}'\n"
  exit 1
fi

DATASTAX_DOWNLOAD_SITE=http://downloads.datastax.com
DOWNLOADS_URL_PREFIX=${DATASTAX_DOWNLOAD_SITE}/cpp-driver/${OS_NAME}/${RELEASE}
DEPENDENCIES_URL_PREFIX=${DOWNLOADS_URL_PREFIX}/dependencies
DRIVER_URL_PREFIX=${DOWNLOADS_URL_PREFIX}/dse

latest_version() {
  local url=${1}
  local latest_version=$(curl -s "${url}" |
    grep -Eo 'href="v[0-9]+\.[0-9]+\.[0-9]+' |
    sed 's/^href="v//' |
    sort -t. -rn -k1,1 -k2,2 -k3,3 |
    head -1)

  echo "${latest_version}"
}

url_directory_count() {
  local url=${1}
  local count=($(echo ${url/${DATASTAX_DOWNLOAD_SITE}/} | tr "/" " "))
  echo "${#count[@]}"
}

install_libuv() {(
  local version=$(latest_version ${DEPENDENCIES_URL_PREFIX}/libuv/)
  local url=${DEPENDENCIES_URL_PREFIX}/libuv/v${version}/
  local cut_dirs=$(url_directory_count ${url})

  [[ -d /tmp/libuv-${version} ]] && rm -rf /tmp/libuv-${version}
  mkdir -p /tmp/libuv-${version}

  cd /tmp/libuv-${version}
  wget -q -r -np -nd -R "index.html*" ${url}
  ls -lh

  if [ "${OS_NAME}" = "centos" ]; then
    sudo rpm -i libuv*.rpm
  else
    sudo dpkg -i libuv*.deb
  fi
)}

install_driver() {(
  local version=$(latest_version ${DRIVER_URL_PREFIX}/)
  local url=${DRIVER_URL_PREFIX}/v${version}/
  local cut_dirs=$(url_directory_count ${url})

  [[ -d /tmp/libdse-${version} ]] && rm -rf /tmp/libdse-${version}
  mkdir -p /tmp/libdse-${version}

  cd /tmp/libdse-${version}
  wget -q -r -np -nd -R "index.html*" ${url}
  ls -lh

  if [ "${OS_NAME}" = "centos" ]; then
    sudo rpm -i *cpp-driver*.rpm
  else
    sudo dpkg -i *cpp-driver*.deb
  fi
)}

install_dependencies() {
  install_libuv
  install_driver
}

build_examples() {(
  [[ -d build ]] && rm -rf build
  mkdir build

  cd build
  cmake ..
  make -j${PROCS}
)}
