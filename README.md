# utilities
Tools and scripts used for NOS project

# Project structure

```
utilities/
├── sonic-db-tools/
│   └── configdb_interaction.py   # Python script for SONiC Config Database interaction
├── wsl/
│   └── setup_wsl_environment.ps1 # PowerShell entry script
└── README.md                     # Top-level: overview of all utilities
```

## Available utilities

### [WSL Setup](./wsl/setup_wsl_environment.ps1)

Installs and configures Ubuntu on WSL, including Docker, Pip, and Jinjator, to
have a working environment for building SONiC. Before running the script, it 
is necessary to change the Execution Policy of Windows PowerShell. To do so,
run the next command:

```
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

<u>Note</u> if by chance you cloned this repository inside WSL and then sent the
script to Windows, the above fix will not work, since the owner of the file is
not your Windows user, but the Ubuntu one.

After that, the setup script can be executed by running:

```PowerShell
.\setup_wsl_environment.ps1
```

This command automatically calls `install` option. The other two options are `move` and `clean`. Move gives you a prompt to move the distro to another disk, if available. Clean removes the distro completely.

<u>Common issues and workarounds</u>

* After using `move` command, sometimes it is possible that the wsl connection cannot be started from the standard user (`Wsl/Service/CreateInstance/MountDisk/HCS/E_ACCESSDENIED` error will be raised). To fix this, run the `wsl` command from admin PowerShell. This will enable you to use wsl in general and from VS Code, for example.
