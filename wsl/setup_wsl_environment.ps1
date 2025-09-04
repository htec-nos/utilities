# setup_wsl_environment.ps1

param (
    [ValidateSet("install", "clean", "move")]
    [string]$Action = "install"
)

function Select-Disk {
    $installedDistros = (wsl --list --quiet) | ForEach-Object { $_.Trim() } | Where-Object { $_.Trim() -ne "" }
    if (-not $installedDistros) {
        Write-Host "`nNo distros installed. Please install a distro first!`n" -ForegroundColor Green
        return
    }

    # Handle multiple distros
    if ($installedDistros.Count -gt 1) {
        Write-Host "`nMultiple distros detected:`n" -ForegroundColor Cyan
        for ($i=0; $i -lt $installedDistros.Count; $i++) {
            Write-Host "$($i+1). $($installedDistros[$i])"
        }
        $distroChoice = Read-Host "Select a distro (1-$($installedDistros.Count))"
        $distro = $installedDistros[$distroChoice - 1]
    } else {
        $distro = $installedDistros
    }
	
	# Remove any special characters that might cause issues
    $distro = $distro -replace '^\*', ''        # Remove leading asterisk
    $distro = $distro -replace '\p{C}+', ''     # Remove control chars (Unicode category C)
    $distro = $distro.Trim()                    # Remove surrounding whitespace

    # Get filesystem drives
    $drives = (Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Root)
    if ($drives.Count -eq 1) {
        Write-Host "`nSingle drive detected. WSL installed on System Drive Location.`n" -ForegroundColor Green
        return
    }

    Write-Host "`nMultiple drives detected. Choose new drive (default exits):`n" -ForegroundColor Cyan
    for ($i=0; $i -lt $drives.Count; $i++) {
        $label = if ($drives[$i] -eq "$env:SystemDrive\") { " (default)" } else { "" }
        Write-Host "$($i+1). $($drives[$i])$label"
    }

    do {
        $selection = Read-Host "Enter a number (1-$($drives.Count))"
        $valid = $selection -match '^[1-9][0-9]*$' -and [int]$selection -le $drives.Count
        if (-not $valid) {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        }
    } while (-not $valid)

    if ($drives[$selection - 1] -eq "$env:SystemDrive\") {
        Write-Host "`nDefault drive picked. Exiting without changes.`n" -ForegroundColor Green
        $cmd = "wsl --shutdown"
        Invoke-Expression $cmd
        return
    }

    $selectedDrive = $drives[$selection - 1].Substring(0,2)  # e.g., "D:"
    $cmd = "wsl --manage `"$distro`" --move `"$selectedDrive\WSL`""
    Write-Host "`nRunning: $cmd`n"
    Invoke-Expression $cmd
    Write-Host "Successfully moved to `"$selectedDrive\WSL`"" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

function Select-UbuntuVersion {
    $distros = @(
        @{ Name = "Ubuntu 20.04"; Id = "Ubuntu-20.04" },
        @{ Name = "Ubuntu 22.04 (recommended)"; Id = "Ubuntu-22.04" },
        @{ Name = "Ubuntu 24.04"; Id = "Ubuntu-24.04" }
    )

    Write-Host "Select the Ubuntu version to install:`n" -ForegroundColor Cyan

    for ($i = 0; $i -lt $distros.Count; $i++) {
        Write-Host "$($i + 1). $($distros[$i].Name)"
    }

    do {
        $selection = Read-Host "Enter a number (1-$($distros.Count))"
        $valid = $selection -match '^[1-9][0-9]*$' -and [int]$selection -le $distros.Count
        if (-not $valid) {
            Write-Host "Invalid selection. Please try again." -ForegroundColor Red
        }
    } while (-not $valid)

    return $distros[[int]$selection - 1].Id
}

function Check-WSLDistroOrPromptRemove {
    param (
        [Parameter(Mandatory)]
        [string]$DistroName
    )

    $installedDistros = wsl --list --quiet

    if ($installedDistros -contains $DistroName) {
        Write-Host "`nDistro '$DistroName' is already installed.`n" -ForegroundColor Red

        $choice = Read-Host "Do you want to remove it and reinstall? (y/N)"
        if ($choice -match '^(y|yes)$') {
            Remove-WSLDistro -DistroName $DistroName
            return  # Continue with fresh install
        } else {
            Write-Host "Exiting without changes." -ForegroundColor Green
            exit
        }
    }

    return  # Distro not installed, safe to continue
}

function Install-WSL {
    # Relaunch as admin if not already elevated
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Restarting script as Administrator..."

        $escapedScriptPath = '"' + $PSCommandPath + '"'
        Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -NoProfile -File $escapedScriptPath $Action" -Verb RunAs
        exit
    }

    Write-Host "Checking necessary Windows features..." -ForegroundColor Cyan

    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmFeature = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform

    if ($wslFeature.State -ne 'Enabled') {
        Write-Host "`n* Enabling WSL feature...`n"
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    } else {
        Write-Host "`n* WSL feature already enabled.`n"
    }

    if ($vmFeature.State -ne 'Enabled') {
        Write-Host "`n* Enabling Virtual Machine Platform feature...`n"
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    } else {
        Write-Host "`n* Virtual Machine Platform already enabled.`n"
    }


    # Write-Host "Installing WSL and Ubuntu...`n" -ForegroundColor Cyan

    $distroId = Select-UbuntuVersion

    Check-WSLDistroOrPromptRemove -DistroName $distroId

    Write-Host "`nInstalling WSL with Ubuntu '$distroId'..." -ForegroundColor Cyan
    Write-Host "Remember to type 'exit' after installation finishes`n" -ForegroundColor Yellow

    # Install WSL (this auto-installs WSL2 and Ubuntu)
    try {
        wsl --install $distroId
    } catch {
        Write-Host "WSL install might have already been completed. Continuing..." -ForegroundColor Yellow
    }

    # Set selected distro as default
    wsl --set-default $distroId

    # Configure the WSL environment
    Write-Host "`nConfiguring environment inside $distroId...`n" -ForegroundColor Cyan

    $setupScript = @'
#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker and other tools:
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add user to Docker group:
sudo groupadd docker
sudo usermod -aG docker $USER

# Install pip and jinjanator:
sudo apt install -y python3-pip
python3 -m pip install jinjanator
echo 'export PATH="/home/$USER/.local/bin:$PATH"' >> ~/.bashrc
'@

    $setupRepoScript = @'
#!/bin/bash

# Create workspace
mkdir ~/workspace/
cd ~/workspace/

#Download all repos
git clone --recurse-submodules https://github.com/htec-nos/sonic-buildimage.git
git clone --recurse-submodules https://github.com/htec-nos/utilities.git

# Checkout to 202505 branch
cd sonic-buildimage/
git checkout 202505

echo 'cd ~/workspace/sonic-buildimage/' >> ~/.bashrc
'@

    # Write the setup script to a temporary file
    $tempScriptPath = "$env:TEMP\wsl_user_setup.sh"
    $setupScript | Out-File -FilePath $tempScriptPath -Encoding utf8 -NoNewline
    (Get-Content $tempScriptPath -Raw).Replace("`r`n", "`n").Replace("`r", "") |
        Set-Content -Force -Encoding utf8 -NoNewline -Path $tempScriptPath
    # Copy script to WSL and execute it
    wsl -d $distroId -- mkdir -p /tmp/setup
    Get-Content -Raw $tempScriptPath | wsl -d $distroId -- bash -c "cat > /tmp/setup/user_setup.sh"
    wsl -d $distroId -- bash -c "chmod +x /tmp/setup/user_setup.sh && bash /tmp/setup/user_setup.sh"
    Write-Host "WSL and Ubuntu installed successfully!" -ForegroundColor Green
    Start-Sleep -Seconds 2
	
	# Setting up the repo
    Write-Host "`nSetting up repo...`n" -ForegroundColor Cyan
	# Write the setup repo script to a temporary file
    $setupRepoScript | Out-File -FilePath $tempScriptPath -Encoding utf8 -NoNewline
    (Get-Content $tempScriptPath -Raw).Replace("`r`n", "`n").Replace("`r", "") |
        Set-Content -Force -Encoding utf8 -NoNewline -Path $tempScriptPath
    # Copy script to WSL and execute it
    wsl -d $distroId -- mkdir -p /tmp/setup
    Get-Content -Raw $tempScriptPath | wsl -d $distroId -- bash -c "cat > /tmp/setup/repo_user_setup.sh"
    wsl -d $distroId -- bash -c "chmod +x /tmp/setup/repo_user_setup.sh && bash /tmp/setup/repo_user_setup.sh"
	Write-Host "Successfully setup repo!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}

function Remove-WSLDistro {
    param (
        [string]$DistroName
    )

    if (-not $DistroName) {
        $installed = @((wsl --list --quiet) -split "`r?`n" | Where-Object { $_ -ne "" })

        if (-not $installed) {
            Write-Host "No WSL distros are currently installed." -ForegroundColor Yellow
            Start-Sleep -Seconds 2
            return
        }

        Write-Host "Select a distro to remove:`n" -ForegroundColor Cyan
        $i = 1
        $installed | ForEach-Object { Write-Host "$i. $_"; $i++ }

        do {
            $choice = Read-Host "Enter a number (1-$($installed.Count))"
        } while (-not ($choice -as [int]) -or $choice -lt 1 -or $choice -gt $installed.Count)

        $DistroName = $installed[$choice - 1]
    }

    # Remove any special characters that might cause issues
    $DistroName = $DistroName -replace '^\*', ''        # Remove leading asterisk
    $DistroName = $DistroName -replace '\p{C}+', ''     # Remove control chars (Unicode category C)
    $DistroName = $DistroName.Trim()                    # Remove surrounding whitespace

    # Confirm before deleting
    $confirm = $(Write-Host "`nAre you sure you want to completely remove '$DistroName'? (y/N)" -ForegroundColor yellow -NoNewline; Read-Host)
    if ($confirm -notmatch '^(y|yes)$') {
        Write-Host "Aborted by user." -ForegroundColor Red
        return
    }

    # Step 1: Unregister the WSL distro
    Write-Host "`nUnregistering $DistroName from WSL...`n" -ForegroundColor Cyan
    try {
        $cmd = "wsl --shutdown"
        Invoke-Expression $cmd
        $cmd = "wsl --unregister $DistroName"
        Invoke-Expression $cmd
        Start-Sleep -Seconds 2
    } catch {
        Write-Warning "Failed to unregister '$DistroName'"
    }

    # Step 2: Attempt to remove matching Appx package
    Write-Host "Checking for matching Appx package..." -ForegroundColor Cyan
    $app = Get-AppxPackage | Where-Object { $_.Name -match [Regex]::Escape($DistroName) -or $_.Name -match "Ubuntu" }

    if ($app) {
        Write-Host "`nRemoving Appx package: $($app.Name)"
        try {
            Remove-AppxPackage -Package $app.PackageFullName
            Write-Host "`nRemoval of '$DistroName' completed." -ForegroundColor Green
        } catch {
            Write-Warning "Failed to remove Appx package: $app"
        }
    } else {
        Write-Host "`nNo Appx package found for '$DistroName'" -ForegroundColor Yellow
    }

    Start-Sleep -Seconds 2
}

switch ($Action) {
    "install" { Install-WSL }
    "clean"   { Remove-WSLDistro }
    "move"    { Select-Disk }
    default   { Write-Host "Unknown action: $Action" -ForegroundColor Red }
}
