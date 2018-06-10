Purpose: bootstrap a 'control host' for Ansible.  This script is intended to be a "Part I" (part II being provided by an Ansible playbook called ensure_control_host). 

Outputs:
* installs ansible, git, libselinux-python and epel-release (the two latter are only on EL systems)
* configures git to the current user account
* checks to see if there is a .bash_profile file present, checks for .bashrc if it is not 
* sets up the current account for passwordless sudo (locally)
* ensures that there is a repo directory in the current user account
* sets up a local ansible inventory along with variables for the first playbook
* git clones an ansible playbook repo from github.com/ryanamorrison

Caveats:
* assumes the host OS is Ubuntu or CentOS (Fedora and Debian may work)
* assumes a new account on a new system (e.g. the non-root account specified during install)
* account that the script is executed in must have sudo permissions (passwordless not necessary -- IOW an account in the group sudo or wheel)
* assumes that initial repo with ansible playbooks will be publically accessible (e.g. Microsoft GitHub)
