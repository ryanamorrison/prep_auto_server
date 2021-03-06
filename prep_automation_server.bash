#!/bin/bash

#defaults
VAR_MY_EMAIL="$(whoami)@$(hostname -d)"
VAR_MY_ACCOUNT="$(whoami)"
VAR_MY_REPODIR="repos"
VAR_GITNAMESPACE="ryanamorrison"
VAR_GITSERVER="https://github.com"
VAR_NEXTPROJECT="ensure_control_platform"

show_help(){

cat<<-ENDOFMESSAGE

prep_automation_server.bash 1.1
Usage: ./prep_automation_server.bash [Overrides]

Overrides:
  --account		The account specified in the git config.  The default is the current user. This
  -a			account will also have a passwordless sudoers file created for them locally
  --login	
  -l		

  --email		The email address specified in the git config. The default is current_user@host_domain.tld
  -e
 
  --directory		The local working directory in this account for repos. Repos pulled from
  -d			git servers will be cloned to this directory. The default is 'repos'.
  --repodir		
  --repodirectory
  -r

  --help		Show this message.
  -h
  
  --namespace		The namespace of the source repo that will be used to set up the environment. The default
  -n			should be fine.

  --server		The git server for the source repo that will be used to set up the environment (e.g. 
  -s			gitlab.com, github.com, etc.). The default should be fine.
  --gitserver		
  -g		

  -type			The type of source git server (github or gitlab)
  -t
ENDOFMESSAGE

}

# borrowed from 
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
    show_help
    exit 0
    ;;
    -n|--namespace)
    VAR_GITNAMESPACE="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--server|-g|--gitserver)
    VAR_GITSERVER="$2"
    shift # past argument
    shift # past value
    ;;
    -t|--type)
    VAR_TYPE_RAW="$2"
    if [ "$VAR_TYPE_RAW" == "gitlab" ]; then
      VAR_GIT_TYPE="gitlab"
    else
      VAR_GIT_TYPE="github"
    fi
    shift # past argument
    shift # past value
    ;;
    -r|--repodir|--repodirectory|-d|--directory)
    VAR_MY_REPODIR="$2"
    shift # past argument
    shift # past value
    ;;    
    -e|--email)
    VAR_MY_EMAIL="$2"
    shift # past argument
    shift # past value
    ;;
    -a|--acccount|-l|--login)
    VAR_MY_ACCOUNT="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    show_help
    exit 0
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -f /etc/redhat-release ]; then
  echo -e "ensuring ansible, git, libselinux-python and epel are present..."
  sudo yum -y install epel-release libselinux-python ansible git unzip
elif [ -f /etc/lsb-release ]; then
  echo -e "ensuring ansible git are present..."
  sudo apt-get -y install ansible git unzip
fi

echo -e "\nensuring git config for current user...\n"
git config --global user.name $VAR_MY_ACCOUNT
git config --global user.email $VAR_MY_EMAIL
sleep 1

echo -e "\ninspecting account to see which profile file is present...\n"
if [ -f $HOME/.bash_profile ]; then
  VAR_LOCAL_PROFILE_SRC=".bash_profile"
elif [ -f $HOME/.bashrc ]; then
  VAR_LOCAL_PROFILE_SRC=".bashrc"
fi
sleep 1

echo -e "\nensuring a sudoers file for the user that is passwordless (for the localhost)...\n"
if [ ! -f "/etc/sudoers.d/$VAR_MY_ACCOUNT" ]; then
  echo "%$VAR_MY_ACCOUNT        ALL = (ALL) NOPASSWD: ALL" > $VAR_MY_ACCOUNT
  sudo mv $VAR_MY_ACCOUNT /etc/sudoers.d/$VAR_MY_ACCOUNT
  sudo chown root:root /etc/sudoers.d/$VAR_MY_ACCOUNT
  sudo chmod 440 /etc/sudoers.d/$VAR_MY_ACCOUNT
  echo -e "\nsudoers file created."
fi
sleep 1

echo -e "\nensuring a repo directory is present...\n"
if [ ! -d $HOME/$VAR_MY_REPODIR ]; then
  mkdir $HOME/$VAR_MY_REPODIR
  echo -e "\nrepo directory created.\n"
fi
sleep 1

echo -e "\nensuring a local inventory for the ansible playbook...\n"
mkdir -p $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all
echo "var_repo_dir: $VAR_MY_REPODIR" > $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all/all.yml
echo "var_git_source_server: $VAR_GITSERVER" >> $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all/all.yml
echo "var_git_source_namespace: $VAR_GITNAMESPACE" >> $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all/all.yml
echo "var_git_source_type: $VAR_GIT_TYPE" >> $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all/all.yml 
echo "var_local_profile_source: $VAR_LOCAL_PROFILE_SRC" >> $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all/all.yml
echo "[local_server]" > $HOME/$VAR_MY_REPODIR/inventories/local/inventory
echo "localhost" >> $HOME/$VAR_MY_REPODIR/inventories/local/inventory
echo "var_initial_script: $(echo "${BASH_SOURCE[0]}" | awk -F'/' '{ print $NF }')" >> $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all/all.yml
echo "var_initial_script_dir: $( cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" >> $HOME/$VAR_MY_REPODIR/inventories/local/group_vars/all/all.yml

sleep 1

echo -e "\nensuring ansible playbook for configuration is present...\n"
if [ $VAR_GITSERVER == "https://github.com" ]; then
curl $VAR_GITSERVER/$VAR_GITNAMESPACE/$VAR_NEXTPROJECT/archive/master.zip -o $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT.zip && unzip $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT.zip -d $HOME/$VAR_MY_REPODIR/
mv $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT-master* $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT
rm $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT.zip
else
# assumes an on-prem gitlab
curl $VAR_GITSERVER/$VAR_GITNAMESPACE/$VAR_NEXTPROJECT/repository/archive.tar.gz?ref=master -o $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT.tar.gz && tar -xvzf $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT.tar.gz -C $HOME/$VAR_MY_REPODIR/
mv $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT-master* $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT
rm $HOME/$VAR_MY_REPODIR/$VAR_NEXTPROJECT.tar.gz
fi

exit 0
