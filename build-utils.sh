#!/bin/env bash



_usage()
{

	echo -e "Usage: $0 [options] target
  Parameters:
   --clang, --gcc, Prefer GNU/Clang compiler.
   --no-virtual, Install target utility into system.
  Targets:\tDescription:
   libimobiledevice, iOS communication.
   plistutil, PLIST converter/decoder.
   irecovery, Recovery/DFU communication.
   libideviceactivation, Device activation.
   ideviceinstaller, IPA installer.
   libimobiledevice-suit, iOS communication suit (includes all utilities).
   pzb, Partical zip downloader.
   plget, Lightweight PLIST parser.
   tsschecker, TSS checker.
   kplooshfinder, Modern kernel patcher.
   kernel64patcher, Legacy kernel patcher.
   kerneldiff, Kernel differs finder.
   img4, Modern utility for img4 manipulation.
   oldimgtool, Modern utility for img3 manipulation .
   img4tool, img4 manipulation utility.
   img3tool, img3 manipulation utility.
   iboot64patcher, thimstar's iboot patcher.
   iboot32patcher, iH8sn0w's iboot patcher.
   hfsplus, checkra1n's fork used for ramdisk manipulation.
   gaster, Better implementation of checkm8.
   plist2json, Converts PLIST into JSON format."
	exit 0

}

_config()
{

# options
		[ -z "$1" ] && _usage
		params="$@"; params="${params,,}"

#	if [ "$(id -u)" = '0' ]; then
#		echo -e "For some reasons you won't be able to run this script as root !\nPlease run the script normally instead.\nAttention: the script will only request a root access only when it installs the missing packages."
#		exit 1
#	fi

	if [[ "$params" = *"--no-virtual"* ]]; then
		virtual_mode="no"
		builded_tag="builded_virtual.tag"
	else
		virtual_mode="yes"
		builded_tag="builded.tag"
	fi
	if [[ "$params" = *"--clang"* ]]; then
		CX="clang"; CXX="clang++"
	elif [[ "$params" = *"--gcc"* ]]; then
		CX="gcc"; CXX="g++"
	else
		CX="gcc"; CXX="g++"
	fi

# check host
		system="$(uname -o)"
	if [ "$system" = "Android" ]; then
		[[ "$PREFIX" = *"com.termux"* ]] && host="termux" || host="unknown"
	elif [ "$system" = "GNU/Linux" ]; then
			distro="$(lsb_release -i | grep 'ID:')"
		if [[ "$distro" = *"Debian"* ]]; then
			host='debian'
		elif [[ "$distro" = *"Ubuntu"* ]]; then
			host='ubuntu'
		else
			host="unknown"
		fi
	fi


	if [ "$host" = "termux" ]; then
		home=~
		export CONFIG_SHELL=$PREFIX/bin/bash # fixes configure issues
		[ "$CX" = "clang" ] && dep="clang binutils-is-llvm git which root-repo automake autoconf make libtool pkg-config m4" || \
						dep="clang binutils-is-llvm git which root-repo automake autoconf make libtool pkg-config m4"
	elif [[ "$host" =~ (debian|ubuntu) ]]; then
		PREFIX="/usr"
		[[ ~ = *"home"* ]] && home=~ || home="/home/$SUDO_USER"
		[ "$CX" = "clang" ] && dep="clang llvm libc6-dev git automake autoconf make libtool pkg-config m4" || \
						dep="gcc g++ libc6-dev git automake autoconf make libtool pkg-config m4"
	else
		echo -e "Error unknown or unsupported host.\nHost: ${system}-${host}\n${distro}"
		exit 1
	fi

# package_tool
	if [ "$host" = "termux" ]; then
		dep_install_cmd="pkg install"
		dep_check_cmd="pkg list-installed"
		dep_update_cmd="pkg update"
		s="installed"
		y="-y"
	elif [[ "$host" =~ (debian|ubuntu) ]]; then
		dep_install_cmd="apt install"
		dep_check_cmd="apt list --installed"
		dep_update_cmd="apt update"
		s="installed"
		y="-y"
	fi

# virtual
	if [ "$virtual_mode" = "yes" ]; then
		src_dir="$home/utils-src"
		root_dir="$home/utils-bin"
		org_prefix="$PREFIX"
		export PREFIX="$root_dir"
		export PKG_CONFIG_PATH="$root_dir/lib/pkgconfig"
		#export PKG_CONFIG_LIBDIR="$root_dir/lib/pkgconfig"
		mkdir -p "$src_dir" "$root_dir/include" "$root_dir/bin" "$root_dir/sbin"
	elif [ "$virtual_mode" = "no" ]; then
		src_dir="$home/utils-src"
		root_dir="$PREFIX"
		org_prefix="$PREFIX"
	fi
		echo "Source location: $src_dir"
		echo "Root location: $root_dir"
		echo "Old Prefix: $org_prefix"
		echo "New Prefix: $PREFIX"
		_dep_installer # install main tools
		_build_selector

}


_build_selector()
{

# chain
	if [[ "$params" = *"plget"* ]]; then
		build_list="plget"
		quick_build
	fi
	if [[ "$params" = *"plistutil"* ]]; then
		build_list="libplist"
		quick_build
	fi
	if [[ "$params" = *"libimobiledevice"* ]]; then
		build_list="libplist libimobiledevice-glue libusbmuxd libtatsu libimobiledevice usbmuxd"
		quick_build
	fi
	if [[ "$params" = *"ideviceinstaller"* ]]; then
		build_list="ideviceinstaller"
		quick_build
	fi
	if [[ "$params" = *"irecovery"* ]]; then
		build_list="libplist libimobiledevice-glue libirecovery"
		quick_build
	fi
	if [[ "$params" = *"idevicerestore"* ]]; then
		build_list="libplist libimobiledevice-glue libtatsu idevicerestore"
		quick_build
	fi
	if [[ "$params" = *"libideviceactivation"* ]]; then
		build_list="libplist libimobiledevice-glue usbmuxd"
		quick_build
	fi
	if [[ "$params" = *"ifuse"* ]]; then
		build_list="libplist libimobiledevice-glue usbmuxd"
		quick_build
	fi
	if [[ "$params" = *"libimobiledevice-suit"* ]]; then
		build_list="libplist libimobiledevice-glue libusbmuxd libtatsu libimobiledevice usbmuxd ideviceinstaller libirecovery idevicerestore libideviceactivation ifuse"
		quick_build
	fi
	if [[ "$params" = *"pzb"* ]]; then
		build_list="libgeneral libfragmentzip partialZipBrowser"
		quick_build
	fi
	if [[ "$params" = *"tsschecker"* ]]; then
		build_list="libgeneral libfragmentzip libplist libirecovery tsschecker"
		quick_build
	fi
	if [[ "$params" = *"plist2json"* ]]; then
		build_list="portableproplib plist2json"
		quick_build
	fi
	if [[ "$params" = *"img4"* ]]; then
		build_list="lzfse img4lib"
		quick_build
	fi
	if [[ "$params" = *"img4tool"* ]]; then
		build_list="libplist libgeneral lzfse img4tool"
		quick_build
	fi
	if [[ "$params" = *"img3tool"* ]]; then
		build_list="libplist libgeneral img3tool"
		quick_build
	fi
	if [[ "$params" = *"iboot64patcher"* ]]; then
		build_list="libgeneral libinsn img3tool img4tool libpatchfinder libipatcher iboot64patcher"
		quick_build
	fi
	if [[ "$params" = *"iboot32patcher"* ]]; then
		build_list="iboot32patcher"
		quick_build
	fi
	if [[ "$params" = *"kplooshfinder"* ]]; then
		build_list="kplooshfinder"
		quick_build
	fi
	if [[ "$params" = *"kernel64patcher"* ]]; then
		build_list="libpatchfinder kernel64patcher"
		quick_build
	fi
	if [[ "$params" = *"kerneldiff"* ]]; then
		build_list="kerneldiff_C"
		quick_build
	fi
	if [[ "$params" = *"oldimgtool"* ]]; then
		build_list="oldimgtool"
		quick_build
	fi
	if [[ "$params" = *"hfsplus"* ]]; then
		build_list="hfsplus"
		quick_build
	fi
	if [[ "$params" = *"gaster"* ]]; then
		build_list="gaster"
		quick_build
	fi

}


_utildeps()
{

		patch=""
	if [ "$1" = "plget" ]; then
		if [ "$host" = "termux" ]; then
			dep="libxml2 automake"
			libs="libxml2"
		elif [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep="libxml2-dev"
			libs="libxml2"
		fi
			src="src"
			configure="configure.sh"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/kallewoof/plget"
			submodules="no"
	elif [ "$1" = "libplist" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX --without-cython"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libplist"
			submodules="no"
	elif [ "$1" = "libimobiledevice-glue" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libimobiledevice-glue"
			submodules="no"
	elif [ "$1" = "libusbmuxd" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libusbmuxd"
			submodules="no"
	elif [ "$1" = "usbmuxd" ]; then
		if [ "$host" = "termux" ]; then
			dep="libusb"
			libs=""
			configure="./autogen.sh --prefix=$PREFIX --without-systemd"
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libusb-1.0-0-dev"
			libs=""
			configure="./autogen.sh --prefix=$PREFIX"
		fi
			src=""
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/usbmuxd"
			submodules="no"
	elif [ "$1" = "libtatsu" ]; then
		if [ "$host" = "termux" ]; then
			dep=""
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libcurl4-openssl-dev"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libtatsu"
			submodules="no"
	elif [ "$1" = "libimobiledevice" ]; then
		if [ "$host" = "termux" ]; then
			dep=""
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libssl-dev"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX --without-cython"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libimobiledevice"
			submodules="no"
	elif [ "$1" = "ideviceinstaller" ]; then
		if [ "$host" = "termux" ]; then
			dep="libzip"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libzip-dev"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/ideviceinstaller"
			submodules="no"
	elif [ "$1" = "libirecovery" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libirecovery"
			submodules="no"
	elif [ "$1" = "idevicerestore" ]; then
		if [ "$host" = "termux" ]; then
			dep="readline libusb openssl libcurl libzip zlib"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="readline-common libusb-1.0-0 openssl libcurl4-openssl-dev libzip4 zlib1g"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/idevicerestore"
			submodules="no"
	elif [ "$1" = "libideviceactivation" ]; then
		if [ "$host" = "termux" ]; then
			dep="libxml2 libcurl openssl"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libxml2 libcurl4-openssl-dev openssl"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libideviceactivation"
			submodules="no"
	elif [ "$1" = "ifuse" ]; then
		if [ "$host" = "termux" ]; then
			dep="libfuse3"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libfuse3-dev"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/ifuse"
			submodules="no"
	elif [ "$1" = "libgeneral" ]; then
		if [ "$host" = "termux" ]; then
			dep=""
			libs=""
			patch="libgeneral"
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/tihmstar/libgeneral"
			submodules="no"
	elif [ "$1" = "libfragmentzip" ]; then
		if [ "$host" = "termux" ]; then
			dep="libcurl zlib"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libcurl4-openssl-dev zlib1g-dev"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/tihmstar/libfragmentzip"
			submodules="no"
	elif [ "$1" = "partialZipBrowser" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/tihmstar/partialZipBrowser"
			submodules="no"
	elif [ "$1" = "tsschecker" ]; then
		if [ "$host" = "termux" ]; then
			dep="libcurl libzip openssl zlib" #autoconf-archive
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libcurl4-openssl-dev libzip4 openssl zlib1g"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/mast3rz3ro/tsschecker"
			submodules="yes"

	elif [ "$1" = "lzfse" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure=""
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/lzfse/lzfse"
			submodules="no"
	elif [ "$1" = "img4lib" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure=""
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="cp $src_dir/img4lib/img4 $PREFIX/bin/"
			repo="https://github.com/xerub/img4lib"
			submodules="no"
	elif [ "$1" = "img4tool" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/tihmstar/img4tool"
			submodules="no"
	elif [ "$1" = "kplooshfinder" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure=""
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="cp $src_dir/KPlooshFinder/KPlooshFinder $PREFIX/bin/"
			repo="https://github.com/plooshi/KPlooshFinder"
			submodules="yes"
	elif [ "$1" = "portableproplib" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure=""
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/void-linux/portableproplib"
			submodules="no"
	elif [ "$1" = "plist2json" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure=""
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/void-linux/plist2json"
			submodules="no"
	elif [ "$1" = "img3tool" ]; then
		if [ "$host" = "termux" ]; then
			dep="openssl zlib"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libcurl4-openssl-dev"
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/tihmstar/img3tool"
			submodules="no"
	elif [ "$1" = "libinsn" ]; then
		if [ "$host" = "termux" ]; then
			dep=""
			libs=""
			patch="libinsn"
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/tihmstar/libinsn"
			submodules="no"
	elif [ "$1" = "libpatchfinder" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
			patch="libpatchfinder"
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/tihmstar/libpatchfinder"
			submodules="no"
	elif [ "$1" = "libipatcher" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/tihmstar/libipatcher"
			submodules="no"
	elif [ "$1" = "iboot64patcher" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="./autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install INSTALL_PREFIX=$PREFIX"
			repo="https://github.com/mast3rz3ro/iBoot64Patcher"
			submodules="no"
	elif [ "$1" = "iboot32patcher" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure=""
			build_cmd="$CX iBoot32Patcher.c finders.c functions.c patchers.c -Wno-multichar -I. -o iBoot32Patcher"
			clean_cmd=""
			install_cmd="cp $src_dir/iBoot32Patcher/iBoot32Patcher $PREFIX/bin/"
			repo="https://github.com/iH8sn0w/iBoot32Patcher"
			submodules="no"
	elif [ "$1" = "kernel64patcher" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure=""
			build_cmd="$CX Kernel64Patcher.c -I$PREFIX/include -o Kernel64Patcher"
			clean_cmd=""
			install_cmd="cp $src_dir/Kernel64Patcher/Kernel64Patcher $PREFIX/bin/"
			repo="https://github.com/Ralph0045/Kernel64Patcher"
			submodules="no"
	elif [ "$1" = "kerneldiff_C" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
			patch="kerneldiff_C"
		fi
			src=""
			configure=""
			build_cmd="$CX kerneldiff.c -o kerneldiff"
			clean_cmd=""
			install_cmd="cp $src_dir/kerneldiff_C/kerneldiff $PREFIX/bin/"
			repo="https://github.com/verygenericname/kerneldiff_C"
			submodules="no"
	elif [ "$1" = "oldimgtool" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
			patch="oldimgtool"
		fi
			src=""
			configure=""
			build_cmd="cargo build"
			clean_cmd=""
			install_cmd="cp target/debug/oldimgtool $PREFIX/bin/"
			repo="https://github.com/justtryingthingsout/oldimgtool"
			submodules="no"
	elif [ "$1" = "hfsplus" ]; then
		if [ "$host" = "termux" ]; then
			dep=""
			libs="android"
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="cmake . -DCMAKE_INSTALL_PREFIX=$PREFIX"
			build_cmd="make -C hfs"
			clean_cmd=""
			install_cmd="cp hfs/hfsplus $PREFIX/bin/"
			repo="https://github.com/verygenericname/libdmg-hfsplus"
			submodules="no"
	elif [ "$1" = "gaster" ]; then
		if [ "$host" = "termux" ]; then
			dep="libusb vim"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libusb-1.0-0-dev vim"
			libs=""
		fi
			src=""
			configure=""
			build_cmd="make libusb"
			clean_cmd=""
			install_cmd="cp gaster $PREFIX/bin/"
			repo="https://github.com/0x7ff/gaster"
			submodules="no"
	fi

}

_patch()
{

	local x
		echo -e "\tApplying patches..."
	if [ "$1" = "oldimgtool" ]; then
		export CARGO_HOME="$src_dir/.cargo"
		sed -i 's/bzero(sp,/memset(sp, 0,/' "$src_dir/$1/src/ext/compression.c"
	elif [ "$1" = "kerneldiff_C" ]; then
		sed -i '1d' "$src_dir/$1/kerneldiff.c"
	elif [ "$1" = "libinsn" ]; then
		sed -i 's/esac/  linux*)\n  LDFLAGS+=" $($CC -print-libgcc-file-name)"\n    \;\;\nesac/' "$src_dir/$1/configure.ac"
	elif [ "$1" = "libgeneral" ]; then
		sed -i 's/LDFLAGS+="/LDFLAGS+=" $($CC -print-libgcc-file-name)/' "$src_dir/$1/configure.ac"
	elif [ "$1" = "libpatchfinder" ]; then
			x="https://github.com/apple-oss-distributions/cctools/archive/refs/tags/cctools-973.0.1.tar.gz"
			mkdir -p "$src_dir/tmp/"
		if [ -s "$src_dir/cctools.tar.gz" ]; then
			:
		elif curl -L "$x" -o "$src_dir/cctools.tar.gz"; then
			:
		else
			exit 1
		fi
			tar -xzf "$src_dir/cctools.tar.gz" -C "$src_dir/tmp/"
			mv $src_dir/tmp/cctoo* "$src_dir/tmp/cctools"
			sed -i 's_#include_//_g' "$src_dir/tmp/cctools/include/mach-o/loader.h"
			sed -i -e 's=<stdint.h>=\n#include <stdint.h>\ntypedef int integer_t;\ntypedef integer_t cpu_type_t;\ntypedef integer_t cpu_subtype_t;\ntypedef integer_t cpu_threadtype_t;\ntypedef int vm_prot_t;=g' "$src_dir/tmp/cctools/include/mach-o/loader.h"
			cp -r $src_dir/tmp/cctools/include/* "$PREFIX/include/"
			rm -rf "$src_dir/tmp"
	fi

}

_clone()
{

	for r in $repo; do
			x="$(basename "$r")"
			echo -e "\tCloning..."
			git clone "$r" "$src_dir/$x" >/dev/null 2>&1
		if [ -d "$src_dir/$x" ]; then
			echo -e "\tCloning done!"
		else
			echo "An error occurred while trying to clone."
			exit 1
		fi
		if [ "$submodules" = "yes" ]; then
				echo -e "\tCloning submodules.."
			if ! git -C "$src_dir/$x" submodule update --init; then
				echo "An error occurred while trying to clone submodules."
				exit 1
			fi
		fi
	done

}


_dep_installer()
{


			echo -e "\tUpdating the packages..."
			$dep_update_cmd

# deps
	for d in $dep; do
			echo -e "\tChecking dependency: $d"
			x="$($dep_check_cmd "$d" 2>/dev/null | grep -coF "$s")"
		if [ "$x" = "0" ]; then
				echo -e "\tInstalling dependency: $d"
				$dep_install_cmd "$d" "$y"
			if [ "$?" -ne "0" ]; then
				echo -e "\tError dependency install failed: $d"
				exit 1
			fi
		elif [ "$x" = "1" ]; then
			echo -e "\tDependency already installed: $d"
		else
			echo "An error occurred while trying to install dependency: $d"
			exit 1
		fi
	done

# libs
	if [ "$virtual_mode" = "yes" ]; then
		for b in $libs; do
				echo -e "\tCopying libs: '${b}'"
			if [ -f "$org_prefix/include/$b" ]; then
				cp "$org_prefix/include/$b" "$root_dir/include/"
			elif [ -d "$org_prefix/include/$b" ]; then
				cp -r "$org_prefix/include/$b" "$root_dir/include/"
			fi
		done
	fi

# patches
	if [ -n "$patch" ]; then
		_patch "$patch"
	fi

}


build()
{

	for r in $repo; do
			x="$(basename $r)"
			echo -ne "\tBuilding: '${x}'\n"
			echo -ne "\tCleaning with: '${clean_cmd}'\n"
			$(cd "$src_dir/$x/$src" && ($clean_cmd) >/dev/null)
			echo -ne "\tConfiguring with: '${configure}'\n"
		if [ -z "$configure" ] || $(cd "$src_dir/$x/$src" && $configure >/dev/null); then
				echo -ne "\tCompiling with: '${build_cmd}'\n"
			if $(cd "$src_dir/$x/$src" && ($build_cmd) >/dev/null); then
					echo -ne "\tInstalling with: '${install_cmd}'\n"
				if $(cd "$src_dir/$x/$src" && ($install_cmd) >/dev/null); then
					echo -ne "\tBuilding succedd: '$x'\n"
					echo -n "">"$src_dir/$x/$builded_tag"
				fi
			else
				echo "An error occurred while trying to compile."
				exit 1
			fi
		else
			echo "An error occurred while trying to configure."
			exit 1
		fi
	done

}


quick_build()
{

		local x
	for x in $build_list; do
			echo -e "Target: ${x}"
		if [ -f "$src_dir/$x/$builded_tag" ]; then
			echo -ne "\tSkipping already builded: '$x'\n"
			continue
		fi
			_utildeps "$x"
			_clone
			_dep_installer
			build
	done

}


_config "$@"
