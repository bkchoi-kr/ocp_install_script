#!/bin/bash

. ./env.sh



# An array to hold the list of packages not installed
missing_packages=()

# Check if required packages are installed
for package in "${packages[@]}"; do
    if ! rpm -q $package &>/dev/null; then
        echo "Package $package is not installed"
        missing_packages+=("$package")
    fi
done

# Print the list of all packages not installed
if [ ${#missing_packages[@]} -gt 0 ]; then
    echo "Missing packages:"
    printf '%s\n' "${missing_packages[@]}"
    exit 1
fi

echo "All required packages for script execution are installed."

# Get the current user
current_user=$(whoami)

# Check if the current user is root
if [ "$current_user" != "root" ]; then

  # Display a message if the user is not root
  echo "Current user ($current_user) does not have sufficient privileges."
  echo "The following line should be added to the /etc/sudoers file"
  echo "======================================================================"
  echo "$current_user ALL=(ALL) NOPASSWD: ALL"
  echo "======================================================================"
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop named
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl start named
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart named
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop haproxy
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl start haproxy
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart haproxy
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop httpd
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl start httpd
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart httpd
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop nfs-server
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl start nfs-server
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart nfs-server
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl stop chronyd
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl start chronyd
#  echo "$current_user ALL=(ALL) NOPASSWD: /usr/bin/systemctl restart chronyd
#  echo "======================================================================"

fi