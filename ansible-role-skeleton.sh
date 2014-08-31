#!/bin/sh
ROLE_NAME=$1
SERVICE_NAME=$1
ROLE_PATH=.
USER_NAME=`git config user.name`
USER_EMAIL=`git config user.email`


if [ $# != 1 ] ; then
	echo "Missing argument role name"
	exit 1
fi

for path in defaults handlers tasks templates vars meta; do
	[ -d $ROLE_PATH/$path ] || mkdir $ROLE_PATH/$path
done

cat <<EOF > $ROLE_PATH/defaults/main.yml
---
# Package states: installed or latest
${ROLE_NAME}_pkg_state: installed

# Service states: started or stopped
${ROLE_NAME}_service_state: started

# Service enabled on startup: yes or no
${ROLE_NAME}_service_enabled: yes
EOF

cat <<EOF > $ROLE_PATH/handlers/main.yml
---
- name: restart ${ROLE_NAME}
  service: name=${SERVICE_NAME} state=restarted

- name: reload ${ROLE_NAME}
  service: name=${SERVICE_NAME} state=reloaded

EOF

cat <<EOF > $ROLE_PATH/tasks/main.yml
---
- name: install ${ROLE_NAME} for Debian OS family
  apt: pkg=${SERVICE_NAME} state={{ ${ROLE_NAME}_pkg_state }}
  when: ansible_os_family == 'Debian'
  tags: ["packages","${ROLE_NAME}"]

- name: install ${ROLE_NAME} for RedHat OS family
  yum: name=${SERVICE_NAME} state={{ ${ROLE_NAME}_pkg_state }}
  when: ansible_os_family == 'RedHat'
  tags: ["packages","${ROLE_NAME}"]

- name: configure ${ROLE_NAME}
  template: src=${SERVICE_NAME}.conf.j2 dest=/etc/${SERVICE_NAME}.conf
  notify: restart ${ROLE_NAME}
  tags: ["configuration","${ROLE_NAME}"]

- name: ensure ${ROLE_NAME} is started/stopped
  service: name=${SERVICE_NAME} state={{ ${ROLE_NAME}_service_state }} enabled={{ ${ROLE_NAME}_service_enabled }}
  tags: ["service","${ROLE_NAME}"]

EOF

cat <<EOF > $ROLE_PATH/templates/$SERVICE_NAME.conf.j2
# {{ ansible_managed }}

EOF


cat <<EOF > $ROLE_PATH/vars/main.yml
---


EOF


cat <<EOF > $ROLE_PATH/.travis.yml
---
language: python
python: "2.7"
before_install:
 - sudo apt-get update -qq
 - sudo apt-get install -qq python-apt python-pycurl
install:
  - pip install ansible
  - ansible --version
script:
  - echo localhost > inventory
  - ansible-playbook -i inventory --syntax-check --list-tasks test.yml
  - ansible-playbook -i inventory --connection=local --sudo -vvvv test.yml
EOF


cat <<EOF > $ROLE_PATH/ansible.cfg
[defaults]
roles_path = ../

EOF

cat <<EOF > $ROLE_PATH/test.yml
---
- hosts: localhost
  remote_user: root
  roles:
    - ansible-role-${ROLE_NAME}
EOF

cat <<EOF > $ROLE_PATH/meta/main.yml
---
galaxy_info:
  author: "${USER_NAME}"
  license: BSD
  min_ansible_version: 1.4
  #
  # Below are all platforms currently available. Just uncomment
  # the ones that apply to your role. If you don't see your
  # platform on this list, let us know and we'll get it added!
  #
  platforms:
  #- name: EL
  # versions:
  #  - all
  #  - 5
  # - 6
  #- name: GenericUNIX
  #  versions:
  #  - all
  #  - any
  #- name: Fedora
  #  versions:
  #  - all
  #  - 16
  #  - 17
  #  - 18
  #  - 19
  #  - 20
  #- name: opensuse
  #  versions:
  #  - all
  #  - 12.1
  #  - 12.2
  #  - 12.3
  #  - 13.1
  #  - 13.2
  #- name: GenericBSD
  #  versions:
  #  - all
  #  - any
  #- name: FreeBSD
  #  versions:
  #  - all
  #  - 8.0
  #  - 8.1
  #  - 8.2
  #  - 8.3
  #  - 8.4
  #  - 9.0
  #  - 9.1
  #  - 9.1
  #  - 9.2
  #- name: Ubuntu
  #  versions:
  #  - all
  #  - lucid
  #  - maverick
  #  - natty
  #  - oneiric
  #  - precise
  #  - quantal
  #  - raring
  #  - saucy
  #  - trusty
  #- name: SLES
  #  versions:
  #  - all
  #  - 10SP3
  #  - 10SP4
  #  - 11
  #  - 11SP1
  #  - 11SP2
  #  - 11SP3
  #- name: GenericLinux
  #  versions:
  #  - all
  #  - any
  #- name: Debian
  #  versions:
  #  - all
  #  - etch
  #  - lenny
  #  - squeeze
  #  - wheezy
  #
  # Below are all categories currently available. Just as with
  # the platforms above, uncomment those that apply to your role.
  #
  categories:
  #- cloud
  #- cloud:ec2
  #- cloud:gce
  #- cloud:rax
  #- database
  #- database:nosql
  #- database:sql
  #- development
  #- monitoring
  #- networking
  #- packaging
  #- system
  #- web
dependencies: []
EOF
