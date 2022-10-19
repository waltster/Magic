#!/bin/bash
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
  brew install -q dialog
}

gui_install() {
  PACKAGES_TEMP_FILE="/tmp/magic_packages.tmp"
  >$PACKAGES_TEMP_FILE

  dialog --clear \
        --title "Package Installation" \
        --backtitle "MAGIC.SH" \
        --checklist "Which packages would you like to install? Press SPACE to select/deselect packages, and UP/DOWN to navigate. Press TAB to navigate between OK and Cancel" \
         25 80 5 \
         "gcc" "GCC" "off" \
         "git" "Git" "off" \
         "greynoise" "Greynoise" "off" \
         "libpcap" "libpcap" "off" \
         "node" "NodeJS" "off" \
         "openssl" "OpenSSL" "off" \
         "python" "Python (v3)" "off" \
         "virtualbox" "VirtualBox" "off" \
         "virtualbox-extension-pack" "VirtualBox Extensions" "off" \
         "wget" "wget" "off" \
         2>$PACKAGES_TEMP_FILE

  read -r -a packages <<< "$(cat $PACKAGES_TEMP_FILE)"

  len=$(wc -w <<< "$packages")
  i=0

  for package in "${packages[@]}"
  do
    echo $((i/len * 100)) | dialog --gauge "Installing packages..." 10 70 0

    if [ $package == "greynoise" ]; then
      brew install -q python >/dev/null
      pip3 install greynoise --upgrade >/dev/null
    else
      brew install -q $package
    fi

    i+=1
  done

  if [ $? -ne 0 ]; then
    dialog --cursor-off-label \
      --backtitle "MAGIC.SH" \
      --title "Package Installation" \
      --clear \
      --msgbox "Unknown error occured." \
      6 80
  else
    dialog --cursor-off-label \
      --backtitle "MAGIC.SH" \
      --title "Package Installation" \
      --clear \
      --msgbox "Installed selected packages!" \
      6 80
  fi
}

gui_keygen() {
  EMAIL_OUTPUT="/tmp/magic_keygen0.tmp"
  PASSWORD_OUTPUT="/tmp/magic_keygen1.tmp"
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
        --erase-on-exit \
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
        --insecure \
        --erase-on-exit \
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
      --erase-on-exit \
      --msgbox "Key generation was successful! Key stored as: \
                ~/.ssh/id_rsa_magic and ~/.ssh/id_rsa_magic.pub" \
      7 80
  else
    dialog --cursor-off-label \
      --backtitle "MAGIC.SH" \
      --erase-on-exit \
      --title "SSH Keygen" \
      --clear \
      --msgbox "There was an error generating keys. Please try manually" \
      7 80
  fi

  rm -rf $EMAIL_OUTPUT $PASSWORD_OUTPUT
}

gui_select_operations() {
  OPERATIONS_TEMP_FILE="/tmp/magic_op.tmp"
  >$OPERATIONS_TEMP_FILE

  dialog --clear \
        --title "Operations Options" \
        --backtitle "MAGIC.SH" \
        --erase-on-exit \
        --checklist "Which would you like to do today? Press SPACE to select/deselect packages, and UP/DOWN to navigate. Press TAB to navigate between OK and Cancel" \
         12 80 4 \
         "install" "Install from a list of packages" "off" \
         "keygen" "Generate SSH Keys" "off" \
         "exit" "Exit" "off" \
         2>$OPERATIONS_TEMP_FILE

  read -r -a operations <<< "$(cat $OPERATIONS_TEMP_FILE)"

  for operation in "${operations[@]}"
  do
    if [ $operation == "install" ]; then
      gui_install
    elif [ $operation == "keygen" ]; then
      gui_keygen
    elif [ $operation == "exit" ]; then
      clear
      echo "Finished!"
      exit 0
    fi
  done

  gui_select_operations
}

homebrew_check
homebrew_update
gui_select_operations
