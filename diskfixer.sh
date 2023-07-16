#!/bin/bash

# \033[0m
echo -e "==================================================="
echo -e "\033[0;92myuko's\033[0m Disk Migration Script."
echo -e ""
echo -e "Hand crafted on: \033[0;92m16/07/23\033[0m"
echo -e "For CentOS version: \033[0;92m7 2009\033[0m"
echo -e "==================================================="
echo -e ""
startTime=$(date +%s)
vg_name=$(vgs --no-headings -o vg_name | awk '{print $1; exit}')
home_lsize_raw=$(echo -e "$home_lvs_output" | awk '{print $1}')
home_lsize=$(echo "$home_lsize_raw" | sed 's/<//g')

root_lvs_output=$(lvs --no-headings -o lv_size /dev/$vg_name/root)
root_lsize_raw=$(echo -e "$root_lvs_output" | awk '{print $1}')
root_lsize=$(echo "$root_lsize_raw" | sed 's/<//g')


mountS() {
    echo -e "[\033[0;91m@\033[0m] Creating 'temp' folder. And moving 'home' content to it.."
    mkdir /temp
    cp -a /home /temp/
    
    echo -e "[\033[0;91m@\033[0m] Unmounting 'home' directory.."
    umount -fl /home
    
    echo -e "[\033[0;91m@\033[0m] Remove the 'home' LVM volume.."
    lvremove /dev/$vg_name/home
    
    fixed_size=${home_lsize^^}
    echo -e "[\033[0;91m@\033[0m] Resize the root LVM volume for additional to add $home_lsize into 'root' directory.."
    lvextend -L+$fixed_size /dev/$vg_name/root
    
    echo -e "[\033[0;91m@\033[0m] Resize the root partition"
    xfs_growfs /dev/mapper/$vg_name-root
    
    echo -e "[\033[0;91m@\033[0m] Copy the 'home' contents back into the 'home' directory"
    cp -a /temp/home /
    
    echo -e "[\033[0;91m@\033[0m] Remove the temporary location"
    yes | rm -rf /temp
    
    
    echo -e "[\033[0;91m@\033[0m] Remove the entry from '/etc/fstab'"
    sudo sed -i "s|^/dev/mapper/$vg_name-home /home|# /dev/mapper/$vg_name-home /home|" /etc/fstab
    
    echo -e "[\033[0;91m@\033[0m] Sync systemd up with the changes.."
    dracut --regenerate-all --force
    
    new_root_lvs_output=$(lvs --no-headings -o lv_size /dev/$vg_name/root)
    new_root_lsize=$(echo -e "$new_root_lvs_output" | awk '{print $1}')
    endTime=$(date +%s)
    ((outTime = ($endTime - $startTime) / 60))
    echo ""
    echo -e "[\033[0;92mOK\033[0m] Script finished. Root now currently have $new_root_lsize. Time consumed:\033[32m $outTime \033[0mMinute!"
}

continuePro() {
    
    echo -e "[\033[0;96m*\033[0m] Fetching directory from Volume: $vg_name"
    
    echo -e "[\033[0;96m*\033[0m] Current 'root' size: $root_lsize"
    
    echo -e "[\033[0;96m*\033[0m] Current 'home' size: $home_lsize"
    
    read -p "Please confirm above information, and do you want to continue? (y/n): " answer
    
    answer=${answer,,}
    
    # Check the user's response
    if [[ "$answer" == "y" || "$answer" == "yes" ]]; then
        echo ""
        echo -e "[\033[0;92m:)\033[0m] Thank you for confirm. The script will continue the job.."
        echo ""
        mountS
        # Add your code here for the "yes" case
    else
        echo -e "[\033[0;91m@\033[0m] Aborted.."
        exit 0
    fi
    
}

if lvs | grep -q 'home'; then
    continuePro
else
    echo -e "[\033[0;91m@\033[0m] Your system does not have 'home' directory. Aborted.."
    exit
fi
