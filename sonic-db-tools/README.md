# Config DB interaction Python script

This script demonstrates how to interact with SONiC Redis Config Database using
the `swsscommon` library that provides database connectivity for SONiC.  

The script performs the following actions:
 - Connects to `CONFIG_DB`
 - Lists all ports under the PORT table
 - Updates Ethernet 0’s MTU field to 9000
 - Reads back the entry to confirm

## Requirements

 - SONiC environment (tested on sonic-vs image running on QEMU)

 - Python 3 (pre-installed on SONiC)

 - swsscommon (included in SONiC images by default)


## Usage

So far, the script was tested under the following conditions:

 - Run `sonic-vs.img` on QEMU. Run the following command in the PowerShell of Windows

```
qemu-system-x86_64 -m 4096 -smp 2 -hda sonic-vs.img -netdev user,id=mgmt0,hostfwd=tcp::2222-:22 -device e1000,netdev=mgmt0
```

 - Copy the script to your SONiC Device

Place `configdb_interaction.py` in a directory on your SONiC host, such as `/home/admin/`

 - Run the script:

```
python3 configdb_interaction.py
```

## Further information

More information about Redis DB interaction in SONIC can be found
in [`Introduction to SONiC Databases`](https://htecgroup.atlassian.net/wiki/spaces/NOSI/pages/5771886631/Introduction+to+SONiC+Databases#3.-Python-script-for-ConfigDB-interaction)