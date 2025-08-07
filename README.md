# utilities
Tools and scripts used for NOS project

# Project structure

```
utilities/
├── wsl-setup/
│   └── setup_wsl_environment.ps1 # PowerShell entry script
└── README.md                     # Top-level: overview of all utilities
```

## Available utilities

### [WSL Setup](./wsl/setup_wsl_environment.ps1)

Installs and configures Ubuntu on WSL, including Docker, Pip, and Jinjator, to
have a working environment for building SONiC.

```bash
.\setup_wsl_environment.ps1
```