# LUKS2 + TPM2 auto-unlock at boot

Based on <https://gist.github.com/Syderitic/23b9c22cb772e1b0e674ed4bb5a3abef>.
Replace `/dev/XXX` with the partition and `<UUID>` with its LUKS UUID (`sudo blkid /dev/XXX`).
Most steps are destructive. Double-check the device first (`lsblk`).

## 1. Create the container and filesystem

```sh
sudo cryptsetup luksFormat --type luks2 /dev/XXX      # temporary passphrase
sudo cryptsetup luksOpen /dev/XXX secure_storage
sudo mkfs.btrfs -L secure_storage -m dup -d single -n 32k --csum xxhash /dev/mapper/secure_storage
sudo cryptsetup luksClose secure_storage
```

Enable zstd compression at mount time (`compress=zstd:3`), not at mkfs.

## 2. Enroll keys

```sh
sudo systemd-cryptenroll /dev/XXX --recovery-key                    # store this safely
sudo systemd-cryptenroll /dev/XXX --tpm2-device=auto --tpm2-pcrs=7
sudo systemd-cryptenroll /dev/XXX --fido2-device=auto               # optional
```

PCR 7 tracks Secure Boot state. Firmware or boot-config changes can break the unlock, and the
recovery key is then needed. The gist suggests PCRs `0+2+4` as an alternative.

## 3. Prefer the TPM slot, drop the temporary passphrase

```sh
sudo systemd-cryptenroll /dev/XXX                                   # list slots, note tpm2 + password slots
sudo cryptsetup config /dev/XXX --priority prefer --key-slot <tpm2_slot>
sudo systemd-cryptenroll /dev/XXX --wipe-slot=<password_slot>
```

Make sure the recovery key works before wiping the password.

## 4. Back up the header

```sh
sudo cryptsetup luksHeaderBackup /dev/XXX --header-backup-file header_secure_storage.img
```

Keep it off the machine. Restore with `cryptsetup luksHeaderRestore`.

## 5. Unlock at boot

### Option A: `/etc/crypttab` (recommended for internal disks)

```
secure_storage  UUID=<UUID>  none  tpm2-device=auto,nofail
```

and in `/etc/fstab`:

```
/dev/mapper/secure_storage  /mnt/secure_storage  btrfs  compress=zstd:3,nofail  0 0
```

Then `sudo systemctl daemon-reload`. On Fedora, if the disk is needed in the initramfs, also
run `sudo dracut -f`. On Arch, use the `sd-encrypt` hook.

### Option B: udev-triggered unit (the gist's approach, for external or hot-plugged drives)

`/etc/systemd/system/luks-unlock@.service`, where the instance name is the LUKS UUID:

```ini
[Unit]
Description=Unlock LUKS device %i via TPM2
BindsTo=dev-disk-by\x2duuid-%i.device
After=dev-disk-by\x2duuid-%i.device

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/cryptsetup luksOpen --token-only /dev/disk/by-uuid/%i cryptvolume-%i
ExecStop=/usr/bin/cryptsetup luksClose cryptvolume-%i
```

`/etc/udev/rules.d/99-luks-unlock.rules` (one line per device):

```
ENV{ID_FS_UUID}=="<UUID>", TAG+="systemd", ENV{SYSTEMD_WANTS}="luks-unlock@<UUID>.service"
```

Apply:

```sh
sudo systemctl daemon-reload
sudo udevadm control --reload-rules && sudo udevadm trigger
```

The unit above is a cleaned-up sketch, not the gist's exact text, which the gist's author
calls messy. Test it by replugging the drive or rebooting, and check
`systemctl status luks-unlock@<UUID>`.

## Troubleshooting

- Asks for a passphrase at boot: the TPM policy no longer matches, so use the recovery key. Then
  re-enroll with `sudo systemd-cryptenroll /dev/XXX --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7`.
- Check what is enrolled: `sudo cryptsetup luksDump /dev/XXX`.
