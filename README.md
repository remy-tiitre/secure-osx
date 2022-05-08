Apple macOS 12 Monterey Security
================================

This is mainly a guide to myself, but might help others as well to adopt enterprise-standard security. CIS Apple macOS 12.0 Monterey Benchmark v1.0.0 is used for audit baseline.

# Clean installation

After macOS 12 Monterey has been installed run:

```$ ./cis_audit.sh```

Some of my lockdown rules might improve security by removing features that you might like to keep. Review the lockdown rules and failing tests before running:

```$ ./osx_lockdown.sh```

Perform the audit again and review the failing and manual rules to improve the security even further.

# Install all the applications and settings

Either do it manually or even better use Ansible or any other automation software to provision all the software and settings. I have separate repository for that [TODO]

# Add YubiKey

## Configure your YubiKey for macOS account login

Guide from [YubiKey](https://support.yubico.com/hc/en-us/articles/360016649059-Using-Your-YubiKey-as-a-Smart-Card-in-macOS)

When you have a new YubiKey, change the pin, puk and management keys first:
```console
$ ykman piv access change-pin
$ ykman piv access change-puk
$ ykman piv access change-management-key --generate --protect
```

Generate certificates to be paired with macOS, you can use different subject value, like your name:
```console
$ ykman piv keys generate 9a --algorithm ECCP256 /tmp/9a.pub
$ ykman piv keys generate 9d --algorithm ECCP256 /tmp/9d.pub
$ ykman piv certificates generate 9a --subject "YubiKey 5C" /tmp/9a.pub
$ ykman piv certificates generate 9d --subject "YubiKey 5C" /tmp/9d.pub
```

Pair the YubiKey with macOS by unpluging and plugging it back to usb port. Sometimes it fails to save the login keychain password, usually unpairing and pairing again fixes the problem:
```console
$ sc_auth identities
$ sudo sc_auth unpair -h HASH
$ sudo sc_auth pair -h HASH -u USERNAME
```

# Configure YubiKey for KeePassXC

Plug in the YubiKey and type ```$ ykman info``` to check the status of the key and ```$ ykman otp info``` to check that the slot 2 is free.

Type ```$ ykman otp chalresp -t -g 2``` to set up slot 2 for the challenge-response mode.

It is strongly recommended to back up your secret key and store it somewhere safe. If you want to set up backup key check that that the slot 2 is free on it and enter ```$ ykman otp chalresp -t 2 [secret]```

Add YubiKey Challenge-Response as additional protection to KeePassXC. Works also with iOS KeePassium.

# Use YubiKey for GPG

It is strongly adviced to use at least bootable "live" linux image in VM and not perform these operations in a daily-use operating system. I use Debian Live image in VMWare Fusion for this purpose.

## Prepare the isolated VM

Download Debian live image:
```console
$ curl -LfO https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/SHA512SUMS
$ curl -LfO https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/SHA512SUMS.sign
$ curl -LfO https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/$(awk '/xfce.iso/ {print $2}' SHA512SUMS)
```

Verify that the image is geniuine:
```console
$ gpg --keyserver hkps://keyring.debian.org --recv DF9B9C49EAA9298432589D76DA87E80D6294BE9B
$ gpg --verify SHA512SUMS.sign SHA512SUMS
$ grep $(sha512sum debian-live-*-amd64-xfce.iso) SHA512SUMS
```

Create a new VM in VMWare Fusion that uses this CD image and isolate it from the host as much as possible (No shared folders, copy & paste sharing etc). At first keep the network connection, we will disconnect it later. All commands from now on are executed inside VM.

Prepare the dependencies:
```console
$ sudo apt update
$ sudo apt -y upgrade
$ sudo apt -y install wget gnupg2 gnupg-agent dirmngr cryptsetup scdaemon pcscd secure-delete hopenpgp-tools yubikey-personalization libssl-dev swig libpcsclite-dev python3-pip python3-pyscard
$ pip3 install PyOpenSSL
$ pip3 install yubikey-manager
$ sudo service pcscd start
```

You have to connect the YubiKey to VM and make sure that it is accessible in VM:
```console
$ ~/.local/bin/ykman openpgp info
```

If it does not work right away you might have to do some additional configuration for [VMWare](https://support.yubico.com/hc/en-us/articles/360013647640-Troubleshooting-Device-Passthrough-with-VMware-Workstation-and-VMware-Fusion)

## Prepare the GPG

Check that the available entropy is good enough (something over 2000):
```console
$ cat /proc/sys/kernel/random/entropy_avail
```

You can increase entropy from YubiKey:
```console
$ echo "SCD RANDOM 512" | gpg-connect-agent | sudo tee /dev/random | hexdump -C
```

## Creating keys

Lets prepare the GPG (You might have to edit the gpg.conf):
```console
$ export GNUPGHOME=$(mktemp -d -t gnupg_$(date +%Y%m%d%H%M)_XXX)

$ grep -ve "^#" $GNUPGHOME/gpg.conf
personal-cipher-preferences AES256 AES192 AES
personal-digest-preferences SHA512 SHA384 SHA256
personal-compress-preferences ZLIB BZIP2 ZIP Uncompressed
default-preference-list SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed
cert-digest-algo SHA512
s2k-digest-algo SHA512
s2k-cipher-algo AES256
charset utf-8
fixed-list-mode
no-comments
no-emit-version
keyid-format 0xlong
list-options show-uid-validity
verify-options show-uid-validity
with-fingerprint
require-cross-certification
no-symkey-cache
use-agent
throw-keyids
```

**!!! Disconnect the network from VM !!!**

### Add master key

Lets create the master password:
```console
$ gpg --gen-random --armor 0 24
```

Copy it to clipboard and/or write it down to paper. Now lets create the master key:
```console
$ gpg --expert --full-generate-key
   (8) RSA (set your own capabilities)
Your selection? 8

   (E) Toggle the encrypt capability
Your selection? E

   (S) Toggle the sign capability
Your selection? S

   (Q) Finished
Your selection? Q

What keysize do you want? (2048) 4096
Key is valid for? (0) 0

Is this correct? (y/N) y

Real name: Remy Tiitre
Email address: remy.tiitre@me.com
Comment: [Optional - leave blank]

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? o

$ export KEYID=0x6A5EA1F042AC80B6 <- This is taken from the output of the last command
```

### Add signing subkey

```console
$ gpg --expert --edit-key $KEYID
gpg> addkey
Please select what kind of key you want:
   (4) RSA (sign only)
Your selection? 4

What keysize do you want? (2048) 4096

Please specify how long the key should be valid.
Key is valid for? (0) 1y

Is this correct? (y/N) y
Really create? (y/N) y
```

### Add encryption subkey

```console
gpg> addkey
Please select what kind of key you want:
   (6) RSA (encrypt only)
Your selection? 6

What keysize do you want? (2048) 4096

Please specify how long the key should be valid.
Key is valid for? (0) 1y

Is this correct? (y/N) y
Really create? (y/N) y
```

### Add authentication subkey

```console
gpg> addkey
   (8) RSA (set your own capabilities)
Your selection? 8

Current allowed actions: Sign Encrypt
   (S) Toggle the sign capability
Your selection? S

Current allowed actions: Encrypt
   (E) Toggle the encrypt capability
Your selection? E

Current allowed actions:
   (A) Toggle the authenticate capability
Your selection? A

Current allowed actions: Authenticate
   (Q) Finished
Your selection? Q

What keysize do you want? (2048) 4096

Please specify how long the key should be valid.
Key is valid for? (0) 1y

Is this correct? (y/N) y
Really create? (y/N) y

gpg> save
```

### Verify keys

```console
$ gpg -K
$ gpg --export $KEYID | hokey lint
```

### Export secret keys

```console
$ gpg --armor --export-secret-keys $KEYID > $GNUPGHOME/mastersub.key
$ gpg --armor --export-secret-subkeys $KEYID > $GNUPGHOME/sub.key
$ gpg --output $GNUPGHOME/revoke.asc --gen-revoke $KEYID
```

### Backup keys

Lets backup the keys to external USB stick. Do not use large one as filling it with random data will take unnecessarily long time, 32GB is big enough. Connect it to VM:
```console
$ sudo dmesg | tail
$ sudo fdisk -l /dev/sdb <- This is taken from the previous command output
$ sudo dd if=/dev/urandom of=/dev/sdb bs=4M status=progress

$ sudo fdisk /dev/sdb
Command (m for help): g
Command (m for help): w

$ sudo fdisk /dev/sdb
Command (m for help): n
Select (default p): p
Partition number (1-4, default 1):
First sector (2048-31116287, default 2048):
Last sector, +/-sectors or +/-size{K,M,G,T,P} (2048-31116287, default 31116287): +25M
Command (m for help): w

$ sudo cryptsetup luksFormat /dev/sdb1
$ sudo cryptsetup luksOpen /dev/sdb1 secret
$ sudo mkfs.ext2 /dev/mapper/secret -L gpg-$(date +%F)
$ sudo mkdir /mnt/encrypted-storage
$ sudo mount /dev/mapper/secret /mnt/encrypted-storage
$ sudo cp -avi $GNUPGHOME /mnt/encrypted-storage/
$ sudo umount /mnt/encrypted-storage/
$ sudo cryptsetup luksClose secret
```

### Export public key

```console
$ sudo fdisk /dev/sdb
Command (m for help): n
Select (default p):
Partition number (2-4, default 2):
First sector (22528-31116287, default 22528):
Last sector, +sectors or +size{K,M,G,T,P} (22528-31116287, default 31116287): +25M
Command (m for help): w

$ sudo mkfs.ext2 /dev/sdb2
$ sudo mkdir /mnt/public
$ sudo mount /dev/sdb2 /mnt/public/
$ gpg --armor --export $KEYID | sudo tee /mnt/public/gpg-$KEYID-$(date +%F).asc
```

### Publish public key

Optionally we can upload the public key to public server as well, but its better to do it later from your host:
```console
$ gpg --send-key $KEYID
$ gpg --keyserver pgp.mit.edu --send-key $KEYID
$ gpg --keyserver keys.gnupg.net --send-key $KEYID
$ gpg --keyserver hkps://keyserver.ubuntu.com:443 --send-key $KEYID
```

## Add keys to YubiKey

Lets prepare the GPG for YubiKey:
```console
$ mkdir ~/.gnupg
$ cat > ~/.gnupg/scdaemon.conf <<'EOF'
disable-ccid
pcsc-driver /usr/lib/x86_64-linux-gnu/libpcsclite.so.1
card-timeout 1
reader-port Yubico YubiKey
EOF

$ systemctl --user restart gpg-agent.service
$ gpg --card-status
```

Lets prepare the YubiKey:
```console
$ gpg --card-edit
gpg/card> admin
gpg/card> kdf-setup

gpg/card> passwd
Your selection? 3
Your selection? 1
Your selection? q

gpg/card> name
Cardholder's surname: Tiitre
Cardholder's given name: Remy

gpg/card> lang
Language preferences: en

gpg/card> login
Login data (account name): remy.tiitre@me.com

gpg/card> list

gpg/card> quit
```

### Transfer keys to YubiKey

```console
$ gpg --edit-key $KEYID

gpg> key 1
gpg> keytocard
Your selection? 1

gpg> key 1
gpg> key 2
gpg> keytocard
Your selection? 2

gpg> key 2
gpg> key 3
gpg> keytocard
Your selection? 3

gpg> save

$ gpg -K
```

Shutdown the VM.

## Configure GPG in macOS

Import the public key to GPG and then:
```console
$ chmod 600 ~/.gnupg/gpg.conf
$ gpg --import /location/of/the/public/key/gpg-0x*.asc
$ export KEYID=0x6A5EA1F042AC80B6
$ gpg --edit-key $KEYID

gpg> trust
Your decision? 5

gpg> quit
```

Configure git to use this key:
```console
$ git config --global user.signingkey 0x6A5EA1F042AC80B6
$ git config --global commit.gpgSign true
```

Here you can find more detailed [guide](https://github.com/drduh/YubiKey-Guide)

# Using GPG for SSH

```console
$ grep -ve "^#" ~/.gnupg/gpg-agent.conf
enable-ssh-support
default-cache-ttl 60
max-cache-ttl 120
pinentry-program /usr/local/bin/pinentry-mac
```

## Replace agents

To launch gpg-agent for use by SSH:
```console
$ cat ~/.zshrc
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
```

To extract the public key from the ssh agent (YubiKey):
```console
$ gpg --card-status <--- Get cardno from output and replace it into next command

$ mkdir -p ~/.ssh
$ ssh-add -L | grep "card-no:[card no from gpg]" > ~/.ssh/id_rsa_yubikey.pub

$ cat << EOF >> ~/.ssh/config
Host [hostname where you want to use YubiKey]
   IdentitiesOnly yes
   IdentityFile ~/.ssh/id_rsa_yubikey.pub
   IdentityAgent ~/.gnupg/S.gpg-agent.ssh
EOF
```

If there are existing SSH keys that you wish to use via gpg-agent, import them:
```
$ ssh-add ~/.ssh/id_rsa && rm ~/.ssh/id_rsa
```

## Change GPG touch policies

```console
$ ykman openpgp keys set-touch aut on
$ ykman openpgp keys set-touch sig on
$ ykman openpgp keys set-touch enc on
```

Reference
=========
* https://github.com/drduh/macOS-Security-and-Privacy-Guide
* https://github.com/laithrafid/osx-ios-sec
* https://github.com/usnistgov/macos_security
* https://github.com/juju4/ansible-harden-darwin
* https://github.com/jamf/CIS-for-macOS-Catalina-CP
* https://github.com/carlospolop/hacktricks/macos/macos-security-and-privilege-escalation
* https://github.com/drduh/YubiKey-Guide
* https://gist.github.com/artizirk/d09ce3570021b0f65469cb450bee5e29
* https://github.com/lfit/itpol/blob/master/protecting-code-integrity.md
