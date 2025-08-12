# utilities
Tools and scripts used for NOS project

# Project structure

```
utilities/
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