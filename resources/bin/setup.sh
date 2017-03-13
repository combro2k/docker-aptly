#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

declare -A NGX_MODULES
export DEBIAN_FRONTEND="noninteractive"

pre_install() {
	apt-get update
	apt-get install -yq curl

	echo "deb http://repo.aptly.info/ nightly main" > /etc/apt/sources.list.d/aptly.list || return 1
	echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" > /etc/apt/sources.list.d/nginx.list || return 1
	
	curl https://www.aptly.info/pubkey.txt | apt-key add - 2>&1 || return 1
	curl http://nginx.org/keys/nginx_signing.key | apt-key add - 2>&1 || return 1

	apt-get update 2>&1 || return 1

    	return 0
}

install() {
	apt-get install -yq aptly nginx bzip2 gzip
}

post_install() {
	apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt 2>&1 || return 1

	chmod +x /usr/local/bin/* || return 1

	return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	tasks=(
        'pre_install'
	'install'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..." || exit 1
		${task} | tee -a "${INSTALL_LOG}" || exit 1
	done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1  || exit 1
		${task} || exit 1
	done
fi
