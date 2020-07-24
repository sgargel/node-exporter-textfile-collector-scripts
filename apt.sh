#!/bin/bash
#
# Description: Expose metrics from apt updates.
#
# Author: Ben Kochie <superq@gmail.com>

upgrades="$(/usr/bin/apt-get --just-print dist-upgrade \
  | /usr/bin/awk -F'[()]' \
      '/^Inst/ { sub("^[^ ]+ ", "", $2); gsub(" ","",$2);
                 sub("\\[", " ", $2); sub("\\]", "", $2); print $2 }' \
  | /usr/bin/sort \
  | /usr/bin/uniq -c \
  | awk '{ gsub(/\\\\/, "\\\\", $2); gsub(/\"/, "\\\"", $2);
           gsub(/\[/, "", $3); gsub(/\]/, "", $3);
           print "apt_upgrades_pending{origin=\"" $2 "\",arch=\"" $NF "\"} " $1}'
)"

echo '# HELP apt_upgrades_pending Apt package pending updates by origin.'
echo '# TYPE apt_upgrades_pending gauge'
if [[ -n "${upgrades}" ]] ; then
  echo "${upgrades}"
else
  echo 'apt_upgrades_pending{origin="",arch=""} 0'
fi

echo '# HELP node_reboot_required Node reboot is required for software updates.'
echo '# TYPE node_reboot_required gauge'
if [[ -f '/run/reboot-required' ]] ; then
  echo 'node_reboot_required 1'
else
  echo 'node_reboot_required 0'
fi

echo '# HELP apt_upgrades_pending_packages Apt package pending updates.'
echo '# TYPE apt_upgrades_pending_packages gauge'
/usr/bin/apt-get --just-print dist-upgrade | grep ^Inst | tr '\( \) \[ \]' ' ' |while read pkg_list;do 
  if [[ -n "${pkg_list}" ]]; then
    pkg=$(echo $pkg_list | awk '{print $2}'); 
    origin=$(echo $pkg_list | awk '{print $(NF-1)}'); 
    arch=$(echo $pkg_list | awk '{print $NF}') ;
    #echo $pkg - $origin - $arch
    echo "apt_upgrades_pending_packages{package=\"${pkg}\",origin=\"${origin}\",arch=\"${arch}\"} 1"
  else
    echo 'apt_upgrades_pending_packages{package="",origin="",arch=""} 0'
  fi
done
