# DOTFILES

## First install
```
sh -c "$(curl -fsSL https://raw.githubusercontent.com/MatteoArella/dotfiles/master/install.sh)"
```

## Usage
Use the bash script ```dotfiles``` to install dotfiles by creating symlinks to the proper directories.

Script usage:
```
./dotfiles install [<package 1> <package 2> ...] creates symlinks to dotfiles
./dotfiles uninstall [<package 1> <package 2> ...] removes symlinks
./dotfiles reinstall [<package 1> <package 2> ...] removes and then re-creates symlinks
```