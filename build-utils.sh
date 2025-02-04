#!/bin/env bash



_usage()
{

	echo -e "Usage: $0 [options] target
  Parameters:
   --clang, --gcc, Prefer GNU/Clang compiler.
   --no-virtual\t Install target utility into system.
  Targets:\tDescription:
   libimobiledevice, iOS communication.
   libplist, PLIST converter/decoder.
   libirecovery, Recovery/DFU communication.
   libideviceactivation, Device activation.
   ideviceinstaller, IPA installer.
   libimobiledevice-suit, iOS communication suit (includes all utilities).
   pzb, Partical zip downloader.
   plget, Lightweight PLIST parser.
   tsschecker, TSS checker."
	exit 0

}

_config()
{

# options
		params="$@"
		[ -z "$params" ] && _usage
	if [ "$(id -u)" = '0' ]; then
		echo -e "For some reasons you won't be able to run this script as root !\nPlease run the script normally instead.\nAttention: the script will only request a root access only when it installs the missing packages."
		exit 1
	fi
	if [[ "$params" = *"--no-virtual"* ]]; then
		virtual_mode="no"
		builded_tag="builded_virtual.tag"
	else
		virtual_mode="yes"
		builded_tag="builded.tag"
	fi
	if [[ "$params" = *"--clang"* ]]; then
		CX="clang"
	elif [[ "$params" = *"--gcc"* ]]; then
		CX="gcc"
	else
		CX="gcc"
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
		dep_install_cmd="sudo apt install"
		dep_check_cmd="apt list --installed"
		dep_update_cmd="sudo apt update"
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
	else
		echo "An error occurred while trying to check the install location."
		exit 1
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
	if [[ "$params" = *"libimobiledevice"* ]]; then
		build_list="libplist libimobiledevice-glue libusbmuxd libtatsu libimobiledevice usbmuxd"
		quick_build
	fi
	if [[ "$params" = *"ideviceinstaller"* ]]; then
		build_list="ideviceinstaller"
		quick_build
	fi
	if [[ "$params" = *"libirecovery"* ]]; then
		build_list="libirecovery"
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

}


_utildeps()
{
	
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
			configure="autogen.sh --prefix=$PREFIX --without-cython"
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
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libusbmuxd"
			submodules="no"
	elif [ "$1" = "usbmuxd" ]; then
		if [ "$host" = "termux" ]; then
			dep="libusb"
			libs=""
			configure="autogen.sh --prefix=$PREFIX --without-systemd"
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libusb-1.0-0-dev"
			libs=""
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX --without-cython"
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
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/libideviceactivation"
			submodules="no"
	elif [ "$1" = "ifuse" ]; then
		if [ "$host" = "termux" ]; then
			dep="libfuse2"
			libs=""
		elif [[ "$host" =~ (debian|ubuntu) ]]; then
			dep="libfuse3-dev"
			libs=""
		fi
			src=""
			configure="autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/libimobiledevice/ifuse"
			submodules="no"
	elif [ "$1" = "libgeneral" ]; then
		if [[ "$host" =~ (debian|ubuntu|termux) ]]; then
			dep=""
			libs=""
		fi
			src=""
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX"
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
			configure="autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/tihmstar/partialZipBrowser"
			submodules="no"
	elif [ "$1" = "tsschecker" ]; then
		if [ "$host" = "termux" ]; then
			dep="libcurl libzip openssl zlib" #autoconf-archive
			libs=""
		elif [ "$host" = "debian" ]; then
			dep="libcurl4-openssl-dev libzip4 openssl zlib1g"
			libs=""
		fi
			src=""
			configure="autogen.sh --prefix=$PREFIX"
			build_cmd="make"
			clean_cmd="make clean"
			install_cmd="make install"
			repo="https://github.com/mast3rz3ro/tsschecker"
			submodules="yes"
	fi

}


_clone()
{

	for r in $repo; do
			x="$(basename "$r")"
			echo -e "Target: ${x}\n\tCloning..."
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

}


build()
{

	for r in $repo; do
			x="$(printf "$r" | sed 's/\//\n/g' | tail -n1)"
		if [ -f "$src_dir/$x/$builded_tag" ]; then
			echo -ne "\tSkipping already builded: '$x'\n"
			return 0
		fi
			echo -ne "\tBuilding: '${x}'\n"
			echo -ne "\tCleaning with: '${clean_cmd}'\n"
			$(cd "$src_dir/$x/$src" && ($clean_cmd) >/dev/null)
			echo -ne "\tConfiguring with: '${configure}'\n"
		if $(cd "$src_dir/$x/$src" && ./$configure >/dev/null); then
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

	for i in $build_list; do
		_utildeps "$i"
		_clone
		_dep_installer
		build
	done

}


_config "$@"
