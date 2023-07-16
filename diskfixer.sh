#!/bin/bash

# \033[0m white
echo -e "==================================================="
echo -e "\033[0;92myuko's\033[0m Disk Migration Script."
echo -e ""
echo -e "Hand crafted on: \033[0;92m16/07/23\033[0m"
echo -e "For CentOS version: \033[0;92m7 2009\033[0m"
echo -e "==================================================="
echo -e ""

if lvs | grep -q 'home'; then
    continuePro
else
    echo -e "[!] Your system does not have 'home' directory. Aborted.."
    exit
fi

vg_name=$(vgs --no-headings -o vg_name | awk '{print $1; exit}')

continuePro() {
  echo -e "[@] Fetching directory from Volume: $VG_NAME"
  root_lvs_output=$(lvs --no-headings -o lv_size /dev/$VG_NAME/root)
  root_lsize=$(echo -e "$root_lvs_output" | awk '{print $1}')
  echo -e "[@] Current 'root' size: $root_lsize"

  home_lvs_output=$(lvs --no-headings -o lv_size /dev/$VG_NAME/home)
  home_lsize=$(echo -e "$home_lvs_output" | awk '{print $1}')
  echo -e "[@] Current 'home' size: $home_lsize"

  read -p "[?] Please confirm above information, and do you want to continue? (y/n): " answqer

  answer=${answer,,}

# Check the user's response
  if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
    echo -e "[:)] Thank you for confirm. The script will continue the job.."
    mountS
    # Add your code here for the "yes" case
  else
    echo -e "[!] Aborted.."
    exit 0
  fi

}

mountS() {

    startTime=$(date +%s)
  echo -e "[*] Creating 'temp' folder. And moving 'home' content to it.."
  mkdir /temp
  cp -a /home /temp/

  echo -e "[*] Unmounting 'home' directory.."
  umount -fl /home

  echo -e "[!] Remove the home LVM volume.."
  lvremove /dev/$VG_NAME/home

  echo -e "[!] Resize the root LVM volume for additional to add $HOME_LSIZE into 'root' directory.."
  lvextend -L+$HOME_LSIZE /dev/$VG_NAME/root

  echo -e "[!] Resize the root partition"
  xfs_growfs /dev/mapper/cl-root

echo -e "[!] Copy the /home contents back into the /home directory"
  cp -a /temp/home /

echo -e "[!] Remove the temporary location"
  rm -rf /temp

echo -e "[!] Remove the entry from /etc/fstab"
sudo sed -i "s|^/dev/mapper/$VG_NAME-home /home|# /dev/mapper/$VG_NAME-home /home|" /etc/fstab

echo -e "[!] Sync systemd up with the changes.."
dracut --regenerate-all --force

endTime=$(date +%s)
((outTime = ($endTime - $startTime) / 60))
echo -e "[:D] Time consumed:\033[32m $outTime \033[0mMinute!"
}
