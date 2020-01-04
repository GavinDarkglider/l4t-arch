#!/bin/bash
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'
distro=0

setup_base(){
mkdir -p tarballs

if [[ ! -e tarballs/ArchLinuxARM-aarch64-latest.tar.gz ]]; then
	wget -O tarballs/ArchLinuxARM-aarch64-latest.tar.gz http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
fi

if [[ ! -d 4.9.140+ ]]; then
	echo modules not found, exiting
	exit 0
fi

if [[ ! -e reboot_payload.bin ]]; then
	wget https://github.com/CTCaer/hekate/releases/download/v5.1.1/hekate_ctcaer_5.1.1_Nyx_0.8.4.zip
	unzip hekate_ctcaer_5.1.1_Nyx_0.8.4.zip hekate_ctcaer_5.1.1.bin
	mv hekate_ctcaer_5.1.1.bin reboot_payload.bin
	rm hekate_ctcaer_5.1.1_Nyx_0.8.4.zip
fi

umount -R build
rm -r build
rm arch-boot.tar.gz arch-root.tar.gz

mkdir build
cp tarballs/*.pkg.* build/
cp build-stage2.sh base-pkgs optional-pkgs build/
cp reboot_payload.bin build/reboot_payload.bin

bsdtar xf tarballs/ArchLinuxARM-aarch64-latest.tar.gz -C build
mkdir -p build/usr/lib/modules
cp -r 4.9.140+  build/usr/lib/modules
cat << EOF >> build/etc/pacman.conf
[switch]
SigLevel = Optional
Server = https://9net.org/l4t-arch/
EOF

echo -e "/dev/mmcblk0p1	/mnt/hos_data	vfat	rw,relatime	0	2\n/boot /mnt/hos_data/l4t-arch/	none	bind	0	0" >> build/etc/fstab

# cursed
mount --bind build build
arch-chroot build ./build-stage2.sh
umount build
}

package_build() {
	umount build

	cd build
	rm etc/pacman.d/gnupg/S.gpg-agent*
	if [ $1 -eq 1 ]; then	
		mv arch-boot.tar.gz ..
		bsdtar -cz -f ../arch-root.tar.gz .

	elif [ $1 -eq 2 ]; then
		mv arch-boot.tar.gz ../blackarch-boot.tar.gz
		bsdtar -cz -f ../blackarch-root.tar.gz .

	elif [ $1 -eq 3 ]; then
		mv arch-boot.tar.gz ../manjaro-boot.tar.gz
		bsdtar -cz -f ../manjaro-root.tar.gz .

	elif [ $1 -eq 4 ]; then
		mv arch-boot.tar.gz ../blackmanjaro-boot.tar.gz
		bsdtar -cz -f blackmanjaro-root.tar.gz .
	fi
	cd ..
}
build_options() {
	echo -e "##################################"
	echo -e "#Choose Which ARCH Disto to Build#"
	echo -e "##################################"
	echo -e "#[1] - Arch Linux                #"
	echo -e "#[2] - BlackArch Linux           #"
	#echo -e "#[3] - Manjaro Linux             #"
	#echo -e "#[4] - BlackArch-Manjaro Mix     #"
	echo -e "#[0] - Exit                      #"
	echo -e "##################################"
	echo -e "Enter Choice: "
	read distro
}
	

add_blackarch(){
	wget https://blackarch.org/strap.sh	
	chmod +x strap.sh
	mv strap.sh build/	
	arch-chroot build ./strap.sh
	arch-chroot build pacman -S blackarch
}

add_manjaro(){
	echo -e "${RED}Manjaro Currently Not available.${NC}"
	echo -e "This currently builds default ARCH for the Switch"
}
	
if [[ `whoami` != root ]]; then
	echo -e hey! run this as ${RED}root${NC}.
	exit
fi

build_options
distro=$((distro))

if [ $distro -eq 0 ]; then
	exit
fi

if [ $distro -gt 4 -o $distro -lt 1 ]; then
	echo "Please choose an availble option"
	build_options
fi

setup_base

#Do extra stuff for Manjaro and Blackarch.
if [[ $distro -gt 1 ]]; then
	if [[ $distro == "2" ]]; then
		add_blackarch
	fi
fi


#elif [[ $distro == "3" ]]; then
#	add_manjaro()	

#elif [[ $distro == "4" ]]; then
#	add_manjaro()
#	add_blackarch() 	
#fi
#fi    

package_build $distro
