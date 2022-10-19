#!/bin/bash
# A fun script for installing all of my favorite packages and dependencies
# @author Walter Pach
platform="unknown"
packages=()
PACKAGES_TMP_FILE="/tmp/magic_packages.tmp"

# Expects to be called with `preliminary $platform` but this can be invoked any
# way, really. This will install package managers and update if needed.
preliminary() {
  echo "[Preliminary] Beginning preliminary checks..."
  if [ $1 == "macos" ]; then
    homebrew_check
    homebrew_update

    echo "[Preliminary] Installing GUI support..."
    install "dialog"
  elif [ $1 == "linux" ]; then
    linux_update

    echo "[Preliminary] Installing GUI support..."
    install "dialog"
    install "build-essentials"
  else
    echo "[Preliminary] Unable to determine system requirements. Please consider creating an issue on the GitHub page."
  fi
}

homebrew_check() {
  brew -v > /dev/null
  if [ $? -ne 0 ]; then
    echo "[Homebrew] Installing Homebrew..."
    echo "[Homebrew] Please enter password when prompted. This is normal behavior."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "[Homebrew] Homebrew installed... skipping!"
  fi
}

homebrew_update() {
  echo "[Homebrew] Updating listings..."
  brew update >/dev/null
  echo "[Homebrew] Upgrading outdated packages..."
  brew upgrade >/dev/null
}

linux_update() {
  echo "[Apt] Updating listings..."
  sudo apt update
  echo "[Apt] Upgrading outdated packages..."
  sudo apt -y upgrade
}

to_mac() {
    case $1 in
      dialog)
        echo "dialog"
        ;;
      virtualbox)
        echo "virtualbox"
        ;;
      virtualbox_extensions)
        echo "virtualbox-extension-pack"
        ;;
      *)
        echo $1
        ;;
    esac
}

to_linux() {
  case $1 in
    dialog)
      echo "dialog"
      ;;
    virtualbox)
      echo "virtualbox"
      ;;
    *)
      echo $1
      ;;
  esac
}

# Main function for installing packages. Basically, it uses an if statement to
# decide which package manager to use and then invokes it. Keep in mind that
# at this stage, the global variable `platform` is used pretty heavily. A
# sane environment is needed, so this should not be called externally.
#
# This function will also transform the package names into their OS-specific
# names. I.E. if a package is named differently for Homebrew than apt.
install() {
  if [ $platform == "macos" ]; then
    local new_package_name=$(to_mac $1)
    brew install -q $new_package_name >/dev/null
  elif [ $platform == "linux" ]; then
    local new_package_name=$(to_linux $1)
    sudo apt install -y $1
  fi
}

# Show the packages GUI.
# @return 0 if normal execution, 1 otherwise.
gui_packages() {
  dialog --cursor-off-label --backtitle "MAGIC.SH" --title "Install Packages?" \
    --yesno "Part of this script supports installing various packages that are \
            commonly used. This will involve selecting the packages you would \
            like installed, as well as updating any that require it. This \
            script will allow you to choose exactly which you would like \
            installed. \n\nContinue?" \
    12 80

  # User requested to skip package installation
  if [ $? -ne 0 ]; then
    return 1
  fi

  dialog --clear \
        --title "Installation Options" \
        --checklist "Which packages would you like to install? Press SPACE to select/deselect packages, and UP/DOWN to navigate. Press TAB to navigate between OK and Cancel" \
         25 80 5 \
         "azure_cli" "Azure Command Line" "off" \
         "azure_functions" "Azure Cloud Functions" "off" \
         "gcc" "GCC essentials" "on" \
         "git" "Git Essentials" "on" \
         "libpcap" "libpcap" "off" \
         "node" "NodeJS" "on" \
         "openssl" "OpenSSL for cert management" "on" \
         "python" "Python" "on" \
         "sshuttle" "SSHuttle for tunnelling" "off" \
         "tensorflow" "TensorFlow" "off" \
         "virtualbox" "Virtualbox and Extensions" "on" \
         "wget" "wget" "on" \
         2>$PACKAGES_TMP_FILE

  read -r -a packages <<< "$(cat $PACKAGES_TMP_FILE)"

  for package in "${packages[@]}"
  do
    install $package
  done

  exit

  rm -f $PACKAGES_TMP_FILE
}

gui_keygen() {
  EMAIL_OUTPUT="/tmp/4040_keygen.tmp"
  PASSWORD_OUTPUT="/tmp/4041_keygen.tmp"
  >$EMAIL_OUTPUT
  >$PASSWORD_OUTPUT

  trap "rm -rf $EMAIL_OUTPUT $PASSWORD_OUTPUT; exit" SIGHUP SIGINT SIGTERM

  dialog --clear --cursor-off-label --backtitle "MAGIC.SH" --title "Generate SSH Keys?" \
    --yesno "Part of this script supports generating a public/private key pair \
             for normal use in cryptographic systems. This will involve \
             entering some basic information. Would you like to generate a new \
             set of keys?" \
    7 80

  # User requested to skip keygen
  if [ $? -ne 0 ]; then
    return 1
  fi

  dialog --title "SSH Keygen" \
        --backtitle "MAGIC.SH" \
        --clear \
        --inputbox "Please enter your email address. This must be a valid \
                    email address and will be tied to your key combination." \
        8 60 \
        2>$EMAIL_OUTPUT

  # User requested to cancel.
  if [ $? -ne 0 ]; then
    rm -rf $EMAIL_OUTPUT $PASSWORD_OUTPUT
    return 1
  fi

  dialog --title "SSH Keygen" \
        --backtitle "MAGIC.SH" \
        --clear \
        --passwordbox "Optional: Enter a passphrase to lock this key." \
        8 60 \
        2>$PASSWORD_OUTPUT

  # User requested to cancel.
  if [ $? -ne 0 ]; then
    rm -rf $EMAIL_OUTPUT $PASSWORD_OUTPUT
    return 1
  fi

  ssh-keygen -t rsa -b 4096 -C $(cat $EMAIL_OUTPUT) -f ~/.ssh/id_rsa_magic -q -N $(cat $PASSWORD_OUTPUT)

  if [ $? -eq 0 ]; then
    dialog --cursor-off-label \
      --clear \
      --backtitle "MAGIC.SH" \
      --title "SSH Keygen" \
      --msgbox "Key generation was successful! Key stored as: \
                ~/.ssh/id_rsa_magic and ~/.ssh/id_rsa_magic.pub" \
      7 80
  else
    dialog --cursor-off-label \
      --backtitle "MAGIC.SH" \
      --title "SSH Keygen" \
      --clear \
      --msgbox "There was an error generating keys. Please try manually" \
      7 80
  fi

  rm -rf $EMAIL_OUTPUT $PASSWORD_OUTPUT
}


if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "[Main] Linux/GNU detected. Beginning preliminary checks."
  platform="linux"
  preliminary $platform
  gui_packages
  gui_keygen
elif [[ "$OSTYPE" == "darwin"* ]]; then
  echo "[Main] macOS detected. Beginning preliminary checks."
  platform="macos"
  preliminary $platform
  gui_packages
  gui_keygen
elif [[ "$OSTYPE" == "cygwin" ]]; then
  echo "[Error] Cygwin is currently not supported. Please consider contributing to the project on GitHub\!"
elif [[ "$OSTYPE" == "msys" ]]; then
  echo "[Error] This platform is currently not supported. Please consider contributing to the project on GitHub\!"
elif [[ "$OSTYPE" == "win32" ]]; then
  echo "[Error] Windows is currently not supported. Please consider contributing to the project on GitHub\!"
elif [[ "$OSTYPE" == "freebsd"* ]]; then
  echo "[Error] FreeBSD is currently not supported. Please consider contributing to the project on GitHub\!"
else
  echo "[Error] Your OS environment could not be determined. Please consider contributing to the project on GitHub\!"
fi

# Install dialog
