#!/bin/bash

# inspired by
# Luke's Auto Rice Boostrapping Script (LARBS)
# by Luke Smith <luke@lukesmith.xyz>
# License: GNU GPLv3

### OPTIONS AND VARIABLES ###
while getopts ":r:b:p:h" o; do case "${o}" in
	h) printf "Optional arguments for custom use:\\n" \
                "  -r: Dotfiles repository (local file or url)\\n" \
                "  -p: Dependencies and programs csv (local file or url)\\n" \
                "  -h: Show this message\\n" && exit ;;
	r) dotfilesrepo=${OPTARG} && git ls-remote "$dotfilesrepo" || exit ;;
	b) repobranch=${OPTARG} ;;
	p) progsfile=${OPTARG} ;;
	*) printf "Invalid option: -%s\\n" "$OPTARG" && exit ;;
esac done

[ -z "$dotfilesrepo" ] && dotfilesrepo="https://github.com/MatteoArella/dotfiles.git"
[ -z "$progsfile" ] && progsfile="https://raw.githubusercontent.com/MatteoArella/dotfiles/master/progs.csv"
[ -z "$repobranch" ] && repobranch="master"

### FUNCTIONS ###

installpkg(){ sudo apt-get install -y "$1" >/dev/null 2>&1 ;}
grepseq="\"^[PGU]*,\""

error() { clear; printf "ERROR:\\n%s\\n" "$1"; exit;}

welcomemsg() { \
	whiptail --title "Welcome!" --msgbox "Welcome!\\n\\nThis script will automatically install a fully-featured Linux desktop." 10 60
	}

maininstall() { # Installs all needed programs from main repo.
	dialog --title "Installation" --infobox "Installing \`$1\` ($n of $total). $1 $2" 5 70
	installpkg "$1"
	}

pipinstall() { \
	dialog --title "Installation" --infobox "Installing the Python package \`$1\` ($n of $total). $1 $2" 5 70
	command -v pip || installpkg python-pip >/dev/null 2>&1
	yes | pip install "$1" >/dev/null 2>&1
	}

snapinstall() { \
	dialog --title "Installation" --infobox "Installing the snap package \`$1\` ($n of $total). $1 $2" 5 70
	command -v snap || installpkg snapd >/dev/null 2>&1
	yes | snap install --classic "$1" >/dev/null 2>&1
	}

gitinstall() {
	progname="$(basename "$1")"
	dir=$(mktemp -d)
	sudo -u "$USER" chown -R "$USER":"$USER" "$dir"
	dialog --title "Installation" --infobox "Installing \`$progname\` ($n of $total) via \`git\`. $(basename "$1") $2" 5 70
	sudo -u "$USER" git clone --depth 1 "$1" "$dir" >/dev/null 2>&1
	cd "$dir" || exit
	./install.sh >/dev/null 2>&1
	}

installationloop() { \
	([ -f "$progsfile" ] && cp "$progsfile" /tmp/progs.csv) || curl -Ls "$progsfile" | sed '/^#/d' | eval grep "$grepseq" > /tmp/progs.csv
	total=$(wc -l < /tmp/progs.csv)
	while IFS=, read -r tag program comment; do
		n=$((n+1))
		echo "$comment" | grep "^\".*\"$" >/dev/null 2>&1 && comment="$(echo "$comment" | sed "s/\(^\"\|\"$\)//g")"
		case "$tag" in
            S) snapinstall "$program" "$comment" ;;
			G) gitinstall "$program" "$comment" ;;
            P) pipinstall "$program" "$comment" ;;
			*) maininstall "$program" "$comment" ;;
		esac
	done < /tmp/progs.csv ;}

putgitrepo() { # Downloads a gitrepo $1 and places the files in $2 only overwriting conflicts
	dialog --infobox "Downloading and installing config files..." 4 60
	[ -z "$3" ] && branch="master" || branch="$repobranch"
	[ ! -d "$2" ] && mkdir -p "$2"
	sudo chown -R "$USER":"$USER" "$2"
	sudo -u "$USER" git clone -b "$branch" "$1" "$2" >/dev/null 2>&1
	eval "$2/dotfiles install"
	}

finalize(){ \
	whiptail --title "All done!" --msgbox "Congrats! Provided there were no hidden errors, the script completed successfully and all the programs and configuration files should be in place." 12 80
	}

### THE ACTUAL SCRIPT ###
installpkg dialog || error "Are you sure you're running this as the root user and have an internet connection?"
installpkg whiptail || error "Are you sure you're running this as the root user and have an internet connection?"

# Welcome user and pick dotfiles.
welcomemsg || error "User exited."

whiptail --title "Installation" --infobox "Installing \`basedevel\` and \`git\` for installing other software required for the installation of other programs." 5 70
installpkg curl
installpkg base-devel
installpkg git


# The command that does all the installing. Reads the progs.csv file and
# installs each needed program the way required.
installationloop

# Install the dotfiles in the user's home directory
putgitrepo "$dotfilesrepo" "$HOME/.dotfiles" "$repobranch"

# Make zsh the default shell for the user.
password=$(whiptail --passwordbox "please enter your secret password" 8 78 --title "Installation" 3>&1 1>&2 2>&3)
sudo -S chsh -s $(which zsh) "${USER}" <<< $password

# Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Last message! Install complete!
finalize
clear
