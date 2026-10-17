name: Zenova RDP Final 2026

on:
  workflow_dispatch:
    inputs:
      machine_id:
        description: "Machine ID"
        required: true
        type: string
      owner_discord_id:
        description: "Owner Discord ID"
        required: false
        default: ""
        type: string
      duration:
        description: "Duration"
        required: false
        default: "5h00m"
        type: choice
        options: ["1h","3h","5h00m"]
      windows_image:
        description: "Windows image"
        required: false
        default: "windows-2025"
        type: choice
        options: ["windows-2025","windows-2022"]
      drive_letter:
        description: "Drive letter"
        required: false
        default: "X"
        type: string
      vhd_size_gb:
        description: "VHD size GB"
        required: false
        default: "1024"
        type: string
      fixed_password:
        description: "Password"
        required: false
        default: "ABC123@"
        type: string
      choco_packages:
        description: "Choco packages"
        required: false
        default: ""
        type: string

permissions:
  contents: write
  actions: write

concurrency:
  group: zenova-rdp-${{ inputs.machine_id }}-${{ github.run_id }}
  cancel-in-progress: false

jobs:
  Zenova-RDP:
    runs-on: ${{ inputs.windows_image }}
    timeout-minutes: 360
    env:
      GH_TOKEN: ${{ secrets.PAT_TOKEN || github.token }}
      GH_REPO: ${{ github.repository }}
      MACHINE_ID_INPUT: ${{ inputs.machine_id }}
      OWNER_DISCORD_ID: ${{ inputs.owner_discord_id }}
      DRIVE_LETTER: ${{ inputs.drive_letter }}
      VHD_SIZE_GB: ${{ inputs.vhd_size_gb }}
      WEB_PORT: "8080"
      SUNSHINE_WEB_PORT: "47990"
    steps:
      - name: Fix Lag Advanced
        shell: pwsh
        run: |
          Write-Host "Fixing lag advanced..."
          $svcs = @('DiagTrack','WSearch','SysMain','WerSvc','XblAuthManager','XblGameSave','XboxNetApiSvc','XboxGipSvc','Spooler','MapsBroker','PcaSvc','TabletInputService','RetailDemo','dmwappushservice','WbioSrvc','PhoneSvc','PrintNotify','WpnService','WpnUserService')
          foreach ($s in $svcs) { try { Stop-Service $s -Force -EA SilentlyContinue; Set-Service $s -StartupType Disabled -EA SilentlyContinue } catch {} }
          try {
              $dwm = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
              if (-not (Test-Path $dwm)) { New-Item $dwm -Force | Out-Null }
              Set-ItemProperty $dwm 'VisualFXSetting' 2 -Type DWord -Force -EA SilentlyContinue
              Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'DragFullWindows' '0' -Force -EA SilentlyContinue
              Set-ItemProperty 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' -Force -EA SilentlyContinue
              Set-ItemProperty 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' -Force -EA SilentlyContinue
          } catch {}
          try {
              Set-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 -Type DWord -Force -EA SilentlyContinue
          } catch {}
          try {
              $cdm = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
              if (Test-Path $cdm) {
                  Set-ItemProperty $cdm 'SubscribedContent-338389Enabled' 0 -Type DWord -Force -EA SilentlyContinue
                  Set-ItemProperty $cdm 'SystemPaneSuggestionsEnabled' 0 -Type DWord -Force -EA SilentlyContinue
                  Set-ItemProperty $cdm 'SoftLandingEnabled' 0 -Type DWord -Force -EA SilentlyContinue
              }
          } catch {}
          try {
              $search = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Search'
              if (-not (Test-Path $search)) { New-Item $search -Force | Out-Null }
              Set-ItemProperty $search 'BingSearchEnabled' 0 -Type DWord -Force -EA SilentlyContinue
              Set-ItemProperty $search 'CortanaConsent' 0 -Type DWord -Force -EA SilentlyContinue
          } catch {}
          powercfg /change standby-timeout-ac 0
          powercfg /change monitor-timeout-ac 0
          powercfg /change disk-timeout-ac 0
          powercfg /hibernate off
          powercfg /setactive SCHEME_MIN
          $bloat = @('Microsoft.3DBuilder','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.XboxApp','Microsoft.XboxGamingOverlay','Microsoft.YourPhone','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.WindowsAlarms','Microsoft.SkypeApp','Microsoft.MicrosoftOfficeHub','Microsoft.MicrosoftSolitaireCollection','Microsoft.People','Microsoft.MixedReality.Portal','Microsoft.OneConnect','Microsoft.Print3D','Microsoft.ScreenSketch','Microsoft.Wallet','Microsoft.WindowsCalculator','Microsoft.WindowsCamera','Microsoft.WindowsCommunicationsApps')
          foreach ($a in $bloat) { Get-AppxPackage -Name "$a" -AllUsers -EA SilentlyContinue | Remove-AppxPackage -AllUsers -EA SilentlyContinue }
          Write-Host "Fix lag done"

      - name: Pre-flight
        shell: pwsh
        run: |
          if (-not (Get-Command 7z -EA SilentlyContinue)) { choco install 7zip -y --no-progress --limit-output }
          if (Get-Command 7z -EA SilentlyContinue) { "HAS_7Z=1" >> "$env:GITHUB_ENV" } else { "HAS_7Z=0" >> "$env:GITHUB_ENV" }
          $b = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
          "OS_BUILD=$b" >> "$env:GITHUB_ENV"

      - name: Fix Audio
        shell: pwsh
        run: |
          Write-Host "Fixing audio..."
          $svcs = @('AudioEndpointBuilder','Audiosrv','MMCSS')
          foreach ($s in $svcs) { try { Set-Service $s -StartupType Automatic -EA SilentlyContinue; Restart-Service $s -Force -EA SilentlyContinue } catch {} }
          Start-Sleep 3
          try {
              $renderKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render'
              if (Test-Path $renderKey) {
                  Get-ChildItem $renderKey -EA SilentlyContinue | ForEach-Object {
                      $propKey = Join-Path name: Zenova RDP v26

on:
  workflow_dispatch:
    inputs:
      machine_id:
        description: "Machine ID"
        required: true
        type: string
      owner_discord_id:
        description: "Owner Discord ID"
        required: false
        default: ""
        type: string
      duration:
        description: "Duration"
        required: false
        default: "5h00m"
        type: choice
        options: ["1h","3h","5h00m"]
      windows_image:
        description: "Windows image"
        required: false
        default: "windows-2025"
        type: choice
        options: ["windows-2025","windows-2022"]
      drive_letter:
        description: "Drive letter"
        required: false
        default: "X"
        type: string
      vhd_size_gb:
        description: "VHD size GB"
        required: false
        default: "1024"
        type: string
      fixed_password:
        description: "Password"
        required: false
        default: "ABC123@"
        type: string
      choco_packages:
        description: "Choco packages"
        required: false
        default: ""
        type: string

permissions:
  contents: write
  actions: write

concurrency:
  group: zenova-rdp-${{ inputs.machine_id }}-${{ github.run_id }}
  cancel-in-progress: false

jobs:
  Zenova-RDP:
    runs-on: ${{ inputs.windows_image }}
    timeout-minutes: 360
    env:
      GH_TOKEN: ${{ secrets.PAT_TOKEN || github.token }}
      GH_REPO: ${{ github.repository }}
      MACHINE_ID_INPUT: ${{ inputs.machine_id }}
      OWNER_DISCORD_ID: ${{ inputs.owner_discord_id }}
      DRIVE_LETTER: ${{ inputs.drive_letter }}
      VHD_SIZE_GB: ${{ inputs.vhd_size_gb }}
      WEB_PORT: "8080"
      SUNSHINE_WEB_PORT: "47990"
    steps:
      - name: Pre-flight
        shell: pwsh
        run: |
          if (-not (Get-Command 7z -EA SilentlyContinue)) { choco install 7zip -y --no-progress --limit-output }
          if (Get-Command 7z -EA SilentlyContinue) { "HAS_7Z=1" >> "$env:GITHUB_ENV" } else { "HAS_7Z=0" >> "$env:GITHUB_ENV" }
          $b = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
          "OS_BUILD=$b" >> "$env:GITHUB_ENV"

      - name: Resolve & Create Release
        shell: pwsh
        run: |
          "JOB_START_EPOCH=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" >> "$env:GITHUB_ENV"
          $cid = (("$env:MACHINE_ID_INPUT").Trim().ToLower() -replace "[^a-z0-9\-]", "-") -replace "\-+","-" -replace "^\-|\-$",""
          if ([string]::IsNullOrWhiteSpace("$cid")) { $cid = "default" }
          "MACHINE_ID=$cid" >> "$env:GITHUB_ENV"
          $relTag = "zenova-storage-$cid"
          $env:RELEASE_TAG = $relTag
          "RELEASE_TAG=$relTag" >> "$env:GITHUB_ENV"
          "STATE_BRANCH=zenova-state-$cid" >> "$env:GITHUB_ENV"
          
          $d = "${{ inputs.duration }}"
          $t = 300; $disp = "5 giÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â"
          if ($d -eq "1h") { $t = 60; $disp = "1 giÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â" }
          if ($d -eq "3h") { $t = 180; $disp = "3 giÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â" }
          "TOTAL_MINUTES=$t" >> "$env:GITHUB_ENV"
          "DISPLAY_TIME=$disp" >> "$env:GITHUB_ENV"
          
          $u = "$env:USERNAME"; $p = "$env:USERPROFILE"
          "RDP_USER=$u" >> "$env:GITHUB_ENV"
          "PROFILE_PATH=$p" >> "$env:GITHUB_ENV"
          $sid = (New-Object System.Security.Principal.NTAccount("$u")).Translate([System.Security.Principal.SecurityIdentifier]).Value
          "RDP_USER_SID=$sid" >> "$env:GITHUB_ENV"
          
          $dl = (("$env:DRIVE_LETTER").Trim() -replace "[^A-Za-z]", "").ToUpper()
          if ((-not "$dl") -or ("$dl" -in @("C","D"))) { $dl = "X" }
          "MOUNT_LETTER=$dl" >> "$env:GITHUB_ENV"
          
          $null = gh release view "$relTag" --repo "$env:GH_REPO" 2>&1
          if (($LASTEXITCODE) -ne 0) {
              $dummy = "$env:RUNNER_TEMP\init.txt"
              Set-Content "$dummy" "Zenova for $cid" -Encoding UTF8
              gh release create "$relTag" "$dummy" --repo "$env:GH_REPO" --title "Zenova ($cid)"
              if (($LASTEXITCODE) -ne 0) { Write-Host "Create release FAIL" -ForegroundColor Red; exit 1 }
          }
          $global:LASTEXITCODE = 0

      - name: Build VHD
        shell: pwsh
        run: |
          $dl = "$env:MOUNT_LETTER"
          $vc = "C:\ZENOVA-VHD"
          New-Item -ItemType Directory -Force -Path "$vc" | Out-Null
          $vf = "$vc\zenova-os.vhdx"
          $sb = ([int64]"$env:VHD_SIZE_GB") * 1GB
          $m = $false
          try {
              if (-not (Test-Path "$vf")) {
                  New-VHD -Path "$vf" -SizeBytes ($sb) -Dynamic | Mount-VHD -PassThru | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter "$dl" -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "ZENOVA" -Confirm:($false) | Out-Null
              } else { Mount-VHD -Path "$vf" }
              $null = Get-PSDrive -Name "$dl" -EA Stop
              if (Test-Path "${dl}:\") { $m = $true }
          } catch {}
          if (-not $m) {
              $fb = "$vc\VIRTUAL"
              New-Item -ItemType Directory -Force -Path "$fb" | Out-Null
              & subst "${dl}:" "$fb"
              $null = New-PSDrive -Name "$dl" -PSProvider FileSystem -Root "${dl}:\" -Scope Global -EA SilentlyContinue
          }
          $sr = "${dl}:\ZENOVA-SYSTEM"
          @("$sr\sessions","$sr\DATA","$sr\OS-OVERLAY","$sr\Users","$sr\installer-cache","${dl}:\Apps") | ForEach-Object { New-Item -ItemType Directory -Force -Path "$_" | Out-Null }
          $bl = "$env:RUNNER_TEMP\baseline.json"
          @{PF64=@(Get-ChildItem "C:\Program Files" -Directory -Force -EA SilentlyContinue | Select-Object -ExpandProperty Name);PF86=@(Get-ChildItem "C:\Program Files (x86)" -Directory -Force -EA SilentlyContinue | Select-Object -ExpandProperty Name);PD=@(Get-ChildItem "C:\ProgramData" -Directory -Force -EA SilentlyContinue | Select-Object -ExpandProperty Name)} | ConvertTo-Json -Depth 4 | Set-Content "$bl" -Encoding UTF8
          @("VHD_CONTAINER=$vc","VHD_FILE=$vf","SHARED_ROOT=$sr","SHARED_SESSION_DIR=$sr\sessions","SHARED_DATA_DIR=$sr\DATA","SHARED_OS_DIR=$sr\OS-OVERLAY","SHARED_STATE_FILE=$sr\sessions\state.json","PROFILE_ROOT=$sr\Users","BASELINE_FILE=$bl","CONTROL_SIGNAL_FILE=$env:RUNNER_TEMP\zenova-control.txt","INSTALLER_CACHE_PERSIST=$sr\installer-cache") | ForEach-Object { $_ >> "$env:GITHUB_ENV" }

      - name: RDP Config
        shell: pwsh
        run: |
          $od = "$env:SHARED_OS_DIR"
          foreach ($d in @("$od\InstalledApps","$od\bin","$od\Installers","$od\Sunshine-Config")) { New-Item -ItemType Directory -Force -Path "$d" | Out-Null }
          "INSTALLER_CACHE=$od\Installers" >> "$env:GITHUB_ENV"
          "SUNSHINE_PERSIST_CFG=$od\Sunshine-Config" >> "$env:GITHUB_ENV"
          Set-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 0 -Force
          $p = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
          Set-ItemProperty "$p" "UserAuthentication" 1 -Force
          Set-ItemProperty "$p" "SecurityLayer" 2 -Force
          Set-ItemProperty "$p" "fDisableAudioCapture" 0 -Type DWord -Force
          Restart-Service TermService -Force -EA SilentlyContinue
          Start-Sleep 3
          Remove-NetFirewallRule -DisplayName "ZENOVA-*" -EA SilentlyContinue
          New-NetFirewallRule -DisplayName "ZENOVA-RDP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389,8080 -RemoteAddress "100.64.0.0/10","127.0.0.1" -Profile Any | Out-Null
          Set-Service TermService -StartupType Automatic -EA SilentlyContinue
          Start-Service TermService -EA SilentlyContinue
          tzutil /s "SE Asia Standard Time"
          powercfg /change standby-timeout-ac 0
          powercfg /change monitor-timeout-ac 0

      - name: Tailscale
        env:
          TAILSCALE_AUTH_KEY: ${{ secrets.TAILSCALE_AUTH_KEY }}
        shell: pwsh
        run: |
          if (-not ("$env:TAILSCALE_AUTH_KEY")) { exit 1 }
          $ts = "C:\Program Files\Tailscale\tailscale.exe"
          if (-not (Test-Path "$ts")) {
              $cm = "$env:INSTALLER_CACHE_PERSIST\tailscale.msi"
              if (-not (Test-Path "$cm")) {
                  for ($i=1; $i -le 3; $i++) { try { Invoke-WebRequest "https://pkgs.tailscale.com/stable/tailscale-setup-latest-amd64.msi" -OutFile "$cm" -UseBasicParsing; if ((Test-Path "$cm") -and ((Get-Item "$cm").Length -gt 5MB)) { break } } catch {}; Start-Sleep 5 }
              }
              if (Test-Path "$cm") { Start-Process msiexec.exe -ArgumentList "/i `"$cm`" /quiet /norestart" -Wait }
              if (-not (Test-Path "$ts")) { choco install tailscale -y --no-progress --limit-output --ignore-checksums }
          }
          if (-not (Test-Path "$ts")) { exit 1 }
          Set-Service "Tailscale" -StartupType Automatic -EA SilentlyContinue
          Start-Service "Tailscale" -EA SilentlyContinue
          Start-Sleep 6
          $th = "zenova-$($env:MACHINE_ID)-$($env:GITHUB_RUN_ID)"
          & "$ts" up "--authkey=$env:TAILSCALE_AUTH_KEY" "--hostname=$th" --accept-routes --accept-dns --reset --unattended
          if (($LASTEXITCODE) -ne 0) { Start-Sleep 5; & "$ts" up "--authkey=$env:TAILSCALE_AUTH_KEY" "--hostname=$th" --accept-routes --accept-dns --reset; if (($LASTEXITCODE) -ne 0) { exit 1 } }
          $ip = $null
          1..20 | ForEach-Object { if (-not $ip) { $o = (& "$ts" ip -4 2>&1 | Out-String).Trim(); if ("$o" -match "^\d+\.\d+\.\d+\.\d+$") { $ip = "$o" } else { Start-Sleep 3 } } }
          if (-not $ip) { exit 1 }
          "TAILSCALE_IP=$ip" >> "$env:GITHUB_ENV"
          "TAILSCALE_HOSTNAME=$th" >> "$env:GITHUB_ENV"

      - name: User Config
        shell: pwsh
        env:
          RDP_PASSWORD_SECRET: ${{ secrets.RDP_PASSWORD }}
        run: |
          $u = "$env:RDP_USER"; $p = "$env:PROFILE_PATH"
          if (-not ([string]::IsNullOrWhiteSpace("$env:RDP_PASSWORD_SECRET"))) { $mp = ("$env:RDP_PASSWORD_SECRET").Trim(); $s = "secret" }
          elseif ("${{ inputs.fixed_password }}") { $mp = "${{ inputs.fixed_password }}"; $s = "input" }
          else { $mp = "ABC123@"; $s = "default" }
          & net accounts /minpwlen:0 /maxpwage:unlimited *> $null
          for ($i=1; $i -le 3; $i++) { & net user "$u" "$mp" *> $null; if ($LASTEXITCODE -eq 0) { break }; Start-Sleep 2 }
          $global:LASTEXITCODE = 0
          & net user "$u" /active:yes /expires:never *> $null
          & net localgroup Administrators "$u" /add *> $null
          & net localgroup "Remote Desktop Users" "$u" /add *> $null
          foreach ($svc in @("AppXSvc","StateRepository","Audiosrv","AudioEndpointBuilder")) { try { Set-Service $svc -StartupType Automatic -EA SilentlyContinue; Start-Service $svc -EA SilentlyContinue } catch {} }
          "RDP_PASS=$mp" >> "$env:GITHUB_ENV"
          "RDP_PASS_SOURCE=$s" >> "$env:GITHUB_ENV"

      - name: Publish state (installing)
        shell: pwsh
        run: |
          $u = "$env:RDP_USER"
          $uO = Get-LocalUser -Name "$u" -EA SilentlyContinue
          $st = [ordered]@{
              machineId = "$env:MACHINE_ID"
              ownerDiscordId = "$env:OWNER_DISCORD_ID"
              user = "$u"
              sid = "$($uO.SID.Value)"
              password = "(xem secret RDP_PASSWORD)"
              passwordSource = "$env:RDP_PASS_SOURCE"
              windowsImage = "${{ inputs.windows_image }}"
              osBuild = "$env:OS_BUILD"
              driveLetter = "$env:MOUNT_LETTER"
              tailscaleIp = "$env:TAILSCALE_IP"
              tailscaleHostname = "$env:TAILSCALE_HOSTNAME"
              durationMinutes = [int]"$env:TOTAL_MINUTES"
              startUtc = [DateTimeOffset]::FromUnixTimeSeconds([long]"$env:JOB_START_EPOCH").UtcDateTime.ToString("o")
              status = "installing"
              step = "installing_apps"
              ready = $false
              appsReady = $false
              lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")
          }
          New-Item -ItemType Directory -Force -Path (Split-Path "$env:SHARED_STATE_FILE") | Out-Null
          $st | ConvertTo-Json -Depth 5 | Set-Content "$env:SHARED_STATE_FILE" -Encoding UTF8
          $td = "$env:RUNNER_TEMP\state-upload"
          New-Item -ItemType Directory -Force -Path "$td" | Out-Null
          Copy-Item "$env:SHARED_STATE_FILE" "$td\state.json" -Force
          gh release upload "$env:RELEASE_TAG" "$td\state.json" --repo "$env:GH_REPO" --clobber
          Write-Host "State: INSTALLING" -ForegroundColor Yellow

      - name: Install Apps
        shell: pwsh
        env:
          PKGS: ${{ inputs.choco_packages }}
        run: |
          $pkgF = "$env:SHARED_OS_DIR\choco-packages.txt"
          $saved = @(); if (Test-Path "$pkgF") { $saved = @(Get-Content "$pkgF" | Where-Object { $_ -match '^[A-Za-z0-9._\-]+$' }) }
          $inp = @()
          if (-not ([string]::IsNullOrWhiteSpace("$env:PKGS"))) { $inp = @("$env:PKGS" -split '\s+' | Where-Object { $_ }) }
          $preset = @('discord','googlechrome','microsoft-edge','spotify','vscode','evkey','bandicam','tailscale')
          $all = @($preset + $saved + $inp | Select-Object -Unique)
          $all | Set-Content "$pkgF" -Encoding UTF8
          
          $failed = @()
          $installed = @()
          foreach ($pkg in $all) {
              Write-Host "ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€¦Ã¢â‚¬Å“ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¦ CÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â i $pkg..." -ForegroundColor Cyan
              choco install "$pkg" -y --no-progress --limit-output --cache "$env:SHARED_OS_DIR\choco-cache"
              $code = $LASTEXITCODE
              if ($code -eq 0 -or $code -eq 3010) { $installed += $pkg } else { $failed += $pkg }
              $global:LASTEXITCODE = 0
          }
          
          Write-Host "ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã¢â‚¬Â¦ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬Ãƒâ€šÃ‚Â¦ Installed: $($installed -join ', ')" -ForegroundColor Green
          if ($failed.Count -gt 0) { Write-Host "ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¢ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¯ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â  Failed: $($failed -join ', ')" -ForegroundColor Yellow }
          
          "APPS_READY=1" >> "$env:GITHUB_ENV"
          "INSTALLED_APPS=$($installed -join ',')" >> "$env:GITHUB_ENV"
          "FAILED_APPS=$($failed -join ',')" >> "$env:GITHUB_ENV"

      - name: Publish state (ready)
        shell: pwsh
        run: |
          $u = "$env:RDP_USER"
          $uO = Get-LocalUser -Name "$u" -EA SilentlyContinue
          $st = [ordered]@{
              machineId = "$env:MACHINE_ID"
              ownerDiscordId = "$env:OWNER_DISCORD_ID"
              user = "$u"
              sid = "$($uO.SID.Value)"
              password = "(xem secret RDP_PASSWORD)"
              passwordSource = "$env:RDP_PASS_SOURCE"
              windowsImage = "${{ inputs.windows_image }}"
              osBuild = "$env:OS_BUILD"
              driveLetter = "$env:MOUNT_LETTER"
              tailscaleIp = "$env:TAILSCALE_IP"
              tailscaleHostname = "$env:TAILSCALE_HOSTNAME"
              durationMinutes = [int]"$env:TOTAL_MINUTES"
              startUtc = [DateTimeOffset]::FromUnixTimeSeconds([long]"$env:JOB_START_EPOCH").UtcDateTime.ToString("o")
              status = "ready"
              step = "ready"
              ready = $true
              appsReady = $true
              installedApps = "$env:INSTALLED_APPS"
              failedApps = "$env:FAILED_APPS"
              lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")
          }
          New-Item -ItemType Directory -Force -Path (Split-Path "$env:SHARED_STATE_FILE") | Out-Null
          $st | ConvertTo-Json -Depth 5 | Set-Content "$env:SHARED_STATE_FILE" -Encoding UTF8
          $td = "$env:RUNNER_TEMP\state-upload"
          New-Item -ItemType Directory -Force -Path "$td" | Out-Null
          Copy-Item "$env:SHARED_STATE_FILE" "$td\state.json" -Force
          gh release upload "$env:RELEASE_TAG" "$td\state.json" --repo "$env:GH_REPO" --clobber
          
          # Verify
          Start-Sleep 2
          $assets = gh release view "$env:RELEASE_TAG" --repo "$env:GH_REPO" --json assets | ConvertFrom-Json
          $hasState = @($assets.assets | Where-Object { $_.name -eq "state.json" }).Count -gt 0
          Write-Host "State: READY (state.json verified: $hasState)" -ForegroundColor Green

      - name: Keepalive
        id: keepalive
        shell: pwsh
        run: |
          $ee = ([long]"$env:JOB_START_EPOCH") + (([long]"$env:TOTAL_MINUTES") * 60)
          $sf = "$env:CONTROL_SIGNAL_FILE"
          $stateFile = "$env:SHARED_STATE_FILE"
          $lhb = Get-Date
          $lastLog = Get-Date
          while ($true) {
              if (Test-Path "$sf") {
                  $cmd = (Get-Content -Raw "$sf" -EA SilentlyContinue).Trim()
                  Remove-Item "$sf" -Force -EA SilentlyContinue
                  if ("$cmd" -eq "RESTART_SESSION") { "FORCE_NEXT_SESSION=1" >> "$env:GITHUB_ENV"; break }
                  if ("$cmd" -eq "STOP_SESSION") { "FORCE_STOP_ONLY=1" >> "$env:GITHUB_ENV"; break }
              }
              if (((Get-Date) - $lhb).TotalSeconds -ge 60) {
                  try {
                      if (Test-Path "$stateFile") {
                          $st = Get-Content -Raw "$stateFile" | ConvertFrom-Json
                          $st.lastUpdatedUtc = (Get-Date).ToUniversalTime().ToString("o")
                          $st | ConvertTo-Json -Depth 5 | Set-Content "$stateFile" -Encoding UTF8
                      }
                  } catch {}
                  $lhb = Get-Date
              }
              
              # Health check services
              $svc = Get-Service "TermService" -EA SilentlyContinue
              if ($svc.Status -ne "Running") { Start-Service "TermService" -EA SilentlyContinue }
              $aud = Get-Service "Audiosrv" -EA SilentlyContinue
              if ($aud.Status -ne "Running") { Start-Service "AudioEndpointBuilder" -EA SilentlyContinue; Start-Service "Audiosrv" -EA SilentlyContinue }
              
              $r = ($ee) - ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
              if (($r) -le 0) { break }
              
              if (((Get-Date) - $lastLog).TotalMinutes -ge 10) {
                  $h = [math]::Floor($r/3600); $m = [math]::Floor(($r%3600)/60)
                  Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Alive | CÃƒÆ’Ã†â€™Ãƒâ€ Ã¢â‚¬â„¢ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â²n: ${h}h${m}m" -ForegroundColor Blue
                  $lastLog = Get-Date
              }
              
              Start-Sleep 2
          }

      - name: Trigger next
        if: ${{ always() && steps.keepalive.outcome == 'success' && env.FORCE_STOP_ONLY != '1' }}
        shell: pwsh
        env:
          DURATION: ${{ inputs.duration }}
          WIN_IMAGE: ${{ inputs.windows_image }}
          FIXED_PASS: ${{ inputs.fixed_password }}
          PKGS: ${{ inputs.choco_packages }}
        run: |
          $wf = [System.IO.Path]::GetFileName(("$env:GITHUB_WORKFLOW_REF" -split "@")[0])
          gh workflow run "$wf" --ref "$env:GITHUB_REF_NAME" -f "machine_id=$env:MACHINE_ID" -f "owner_discord_id=$env:OWNER_DISCORD_ID" -f "duration=$env:DURATION" -f "windows_image=$env:WIN_IMAGE" -f "fixed_password=$env:FIXED_PASS" -f "choco_packages=$env:PKGS"
          if (($LASTEXITCODE) -ne 0) { throw "Trigger next fail" }.PSPath 'Properties'
                      if (Test-Path $propKey) {
                          Set-ItemProperty $propKey '{1da5d803-d492-4edd-8c23-e0c0ffee7f0e},5' 0 -Type DWord -Force -EA SilentlyContinue
                          Set-ItemProperty $propKey '{b3f8fa53-0004-438e-9003-51a46e139bfc},3' 0 -Type DWord -Force -EA SilentlyContinue
                      }
                  }
              }
          } catch {}
          Restart-Service Audiosrv -Force -EA SilentlyContinue
          Write-Host "Audio fixed"

      - name: Resolve & Create Release
        shell: pwsh
        run: |
          "JOB_START_EPOCH=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())" >> "$env:GITHUB_ENV"
          $cid = (("$env:MACHINE_ID_INPUT").Trim().ToLower() -replace "[^a-z0-9\-]", "-") -replace "\-+","-" -replace "^\-|\-$",""
          if ([string]::IsNullOrWhiteSpace("$cid")) { $cid = "default" }
          "MACHINE_ID=$cid" >> "$env:GITHUB_ENV"
          $relTag = "zenova-storage-$cid"
          $env:RELEASE_TAG = $relTag
          "RELEASE_TAG=$relTag" >> "$env:GITHUB_ENV"
          "STATE_BRANCH=zenova-state-$cid" >> "$env:GITHUB_ENV"
          
          $d = "${{ inputs.duration }}"
          $t = 300; $disp = "5 giÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â"
          if ($d -eq "1h") { $t = 60; $disp = "1 giÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â" }
          if ($d -eq "3h") { $t = 180; $disp = "3 giÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â¡ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â»ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â" }
          "TOTAL_MINUTES=$t" >> "$env:GITHUB_ENV"
          "DISPLAY_TIME=$disp" >> "$env:GITHUB_ENV"
          
          $u = "$env:USERNAME"; $p = "$env:USERPROFILE"
          "RDP_USER=$u" >> "$env:GITHUB_ENV"
          "PROFILE_PATH=$p" >> "$env:GITHUB_ENV"
          $sid = (New-Object System.Security.Principal.NTAccount("$u")).Translate([System.Security.Principal.SecurityIdentifier]).Value
          "RDP_USER_SID=$sid" >> "$env:GITHUB_ENV"
          
          $dl = (("$env:DRIVE_LETTER").Trim() -replace "[^A-Za-z]", "").ToUpper()
          if ((-not "$dl") -or ("$dl" -in @("C","D"))) { $dl = "X" }
          "MOUNT_LETTER=$dl" >> "$env:GITHUB_ENV"
          
          $null = gh release view "$relTag" --repo "$env:GH_REPO" 2>&1
          if (($LASTEXITCODE) -ne 0) {
              $dummy = "$env:RUNNER_TEMP\init.txt"
              Set-Content "$dummy" "Zenova for $cid" -Encoding UTF8
              gh release create "$relTag" "$dummy" --repo "$env:GH_REPO" --title "Zenova ($cid)"
              if (($LASTEXITCODE) -ne 0) { Write-Host "Create release FAIL" -ForegroundColor Red; exit 1 }
          }
          $global:LASTEXITCODE = 0

      - name: Build VHD
        shell: pwsh
        run: |
          $dl = "$env:MOUNT_LETTER"
          $vc = "C:\ZENOVA-VHD"
          New-Item -ItemType Directory -Force -Path "$vc" | Out-Null
          $vf = "$vc\zenova-os.vhdx"
          $sb = ([int64]"$env:VHD_SIZE_GB") * 1GB
          $m = $false
          try {
              if (-not (Test-Path "$vf")) {
                  New-VHD -Path "$vf" -SizeBytes ($sb) -Dynamic | Mount-VHD -PassThru | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -DriveLetter "$dl" -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "ZENOVA" -Confirm:($false) | Out-Null
              } else { Mount-VHD -Path "$vf" }
              $null = Get-PSDrive -Name "$dl" -EA Stop
              if (Test-Path "${dl}:\") { $m = $true }
          } catch {}
          if (-not $m) {
              $fb = "$vc\VIRTUAL"
              New-Item -ItemType Directory -Force -Path "$fb" | Out-Null
              & subst "${dl}:" "$fb"
              $null = New-PSDrive -Name "$dl" -PSProvider FileSystem -Root "${dl}:\" -Scope Global -EA SilentlyContinue
          }
          $sr = "${dl}:\ZENOVA-SYSTEM"
          @("$sr\sessions","$sr\DATA","$sr\OS-OVERLAY","$sr\Users","$sr\installer-cache","${dl}:\Apps") | ForEach-Object { New-Item -ItemType Directory -Force -Path "$_" | Out-Null }
          $bl = "$env:RUNNER_TEMP\baseline.json"
          @{PF64=@(Get-ChildItem "C:\Program Files" -Directory -Force -EA SilentlyContinue | Select-Object -ExpandProperty Name);PF86=@(Get-ChildItem "C:\Program Files (x86)" -Directory -Force -EA SilentlyContinue | Select-Object -ExpandProperty Name);PD=@(Get-ChildItem "C:\ProgramData" -Directory -Force -EA SilentlyContinue | Select-Object -ExpandProperty Name)} | ConvertTo-Json -Depth 4 | Set-Content "$bl" -Encoding UTF8
          @("VHD_CONTAINER=$vc","VHD_FILE=$vf","SHARED_ROOT=$sr","SHARED_SESSION_DIR=$sr\sessions","SHARED_DATA_DIR=$sr\DATA","SHARED_OS_DIR=$sr\OS-OVERLAY","SHARED_STATE_FILE=$sr\sessions\state.json","PROFILE_ROOT=$sr\Users","BASELINE_FILE=$bl","CONTROL_SIGNAL_FILE=$env:RUNNER_TEMP\zenova-control.txt","INSTALLER_CACHE_PERSIST=$sr\installer-cache") | ForEach-Object { $_ >> "$env:GITHUB_ENV" }

      - name: RDP Config
        shell: pwsh
        run: |
          $od = "$env:SHARED_OS_DIR"
          foreach ($d in @("$od\InstalledApps","$od\bin","$od\Installers","$od\Sunshine-Config")) { New-Item -ItemType Directory -Force -Path "$d" | Out-Null }
          "INSTALLER_CACHE=$od\Installers" >> "$env:GITHUB_ENV"
          "SUNSHINE_PERSIST_CFG=$od\Sunshine-Config" >> "$env:GITHUB_ENV"
          Set-ItemProperty "HKLM:\System\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" 0 -Force
          $p = "HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
          Set-ItemProperty "$p" "UserAuthentication" 1 -Force
          Set-ItemProperty "$p" "SecurityLayer" 2 -Force
          Set-ItemProperty "$p" "fDisableAudioCapture" 0 -Type DWord -Force
          Restart-Service TermService -Force -EA SilentlyContinue
          Start-Sleep 3
          Remove-NetFirewallRule -DisplayName "ZENOVA-*" -EA SilentlyContinue
          New-NetFirewallRule -DisplayName "ZENOVA-RDP" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3389,8080 -RemoteAddress "100.64.0.0/10","127.0.0.1" -Profile Any | Out-Null
          Set-Service TermService