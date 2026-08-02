# Configures and builds retropad on Windows using llvm-mingw (UCRT), installed
# with:  winget install MartinStorsjo.LLVM-MinGW.UCRT
#
#   ./build.ps1                     Build Debug and Release
#   ./build.ps1 -Config Release     Build Release only
#   ./build.ps1 -Clean              Wipe the build directories first
#
# -Arch accepts only x86_64 today; see the note in build.sh.
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("x86_64")]
    [string]$Arch = "x86_64",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Debug", "Release", "all")]
    [string]$Config = "all",

    [switch]$Clean
)

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

function Build-Config {
    param($TargetArch, $TargetConfig)

    $BuildDir = Join-Path $ProjectRoot "build/$TargetArch-$TargetConfig"
    $Toolchain = Join-Path $ProjectRoot "cmake/toolchain-$TargetArch-mingw.cmake"

    Write-Host "`n>>> Building $TargetArch ($TargetConfig)..." -ForegroundColor Cyan

    if ($Clean -and (Test-Path $BuildDir)) {
        Write-Host "Cleaning $BuildDir..." -ForegroundColor Gray
        Remove-Item -Recurse -Force $BuildDir
    }

    if (!(Test-Path $BuildDir)) {
        New-Item -ItemType Directory -Path $BuildDir | Out-Null
    }

    cmake -S $ProjectRoot -B $BuildDir -G "MinGW Makefiles" `
          "-DCMAKE_BUILD_TYPE=$TargetConfig" `
          "-DCMAKE_TOOLCHAIN_FILE=$Toolchain" `
          -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

    cmake --build $BuildDir -j
}

$Configs = if ($Config -eq "all") { @("Debug", "Release") } else { @($Config) }

foreach ($c in $Configs) {
    Build-Config -TargetArch $Arch -TargetConfig $c
}
