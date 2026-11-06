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

### Adding a passphrase back later

A LUKS2 container holds several keyslots, so a typeable passphrase can be added next to the TPM2
and recovery slots at any time (for example before a Secure Boot or firmware change):

```sh
sudo systemd-cryptenroll /dev/XXX --password     # asks for an existing passphrase/recovery key, then the new one
# or, equivalently:
sudo cryptsetup luksAddKey /dev/XXX
```

Check the result with `sudo systemd-cryptenroll /dev/XXX`. Later `--wipe-slot=tpm2` leaves the
password slot alone.

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

## Re-enroll the TPM after a firmware update

A firmware or Secure Boot change alters the PCR values the TPM key was sealed to, so the unlock
fails and boot asks for the recovery key. Unlock with it, then replace the stale TPM2 slot:

```sh
sudo systemd-cryptenroll /dev/XXX                                   # list slots, confirm the tpm2 one
sudo systemd-cryptenroll /dev/XXX --wipe-slot=tpm2                  # asks for recovery key/passphrase
sudo systemd-cryptenroll /dev/XXX --tpm2-device=auto --tpm2-pcrs=7  # match the PCRs used in step 2
```

The initramfs does not need rebuilding, because only the LUKS header changes. Rebuild it
(`sudo dracut -f`, or `mkinitcpio -P` on Arch) only if the volume is unlocked in the initramfs,
as in step 5.

Then reboot and confirm it unlocks without a prompt. Notes:

- `--wipe-slot=tpm2` removes only TPM2 slots. The recovery key and passphrase slots stay.
- If you enrolled with a PIN, add `--tpm2-with-pin=yes` again.
- PCR 7 only helps if Secure Boot is on (`mokutil --sb-state`).
- The crypttab entry for the volume needs `tpm2-device=auto` in its options, or the TPM is not
  tried.

## Troubleshooting

- Asks for a passphrase at boot: the TPM policy no longer matches. Use the recovery key, then
  follow "Re-enroll the TPM after a firmware update" above.
- Check what is enrolled: `sudo cryptsetup luksDump /dev/XXX`.
