# Ensure script halts immediately on fatal errors
$ErrorActionPreference = "Stop"

# Add MSYS2 UCRT64 path dynamically if not present
if ($env:Path -notlike "*C:\msys64\ucrt64\bin*") {
    $env:Path += ";C:\msys64\ucrt64\bin"
}

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "   GVF Dynamics, LLC — Pre-Silicon Verification    " -ForegroundColor Cyan
Write-Host "   Target: GVF Engine™ (gvf_core_top + gvf_core_tb)  " -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan

# 1. Define Paths and Files
$RtlDir     = "C:\Users\17722\OneDrive\Desktop\GVF_Master_Project\GVF-Engine-Sim\hardware\rtl"
$SimOutDir  = "$RtlDir\sim_build"
$SimBinary  = "$SimOutDir\gvf_sim.vvp"
$TopModule  = "$RtlDir\gvf_core_top.sv"
$Testbench  = "$RtlDir\gvf_core_tb.sv"

# 2. Check Prerequisites (iverilog & vvp)
Write-Host "`n[1/4] Checking EDA Tool Availability..." -ForegroundColor Yellow

$iverilogCmd = Get-Command iverilog -ErrorAction SilentlyContinue
$vvpCmd      = Get-Command vvp -ErrorAction SilentlyContinue

if (-not $iverilogCmd) {
    Write-Host "[ERROR] 'iverilog' was not found in System PATH." -ForegroundColor Red
    exit 1
}

if (-not $vvpCmd) {
    Write-Host "[ERROR] 'vvp' runtime was not found in System PATH." -ForegroundColor Red
    exit 1
}

Write-Host "  -> iverilog found: $($iverilogCmd.Source)" -ForegroundColor Green
Write-Host "  -> vvp found:      $($vvpCmd.Source)" -ForegroundColor Green

# 3. Create Build Directory
if (-not (Test-Path $SimOutDir)) {
    New-Item -ItemType Directory -Path $SimOutDir | Out-Null
}

# 4. Compile RTL & Testbench using iverilog (-g2012 for SystemVerilog support)
Write-Host "`n[2/4] Compiling RTL and Testbench with SystemVerilog-2012 flags..." -ForegroundColor Yellow

Set-Location $RtlDir

try {
    iverilog -g2012 -o $SimBinary $TopModule $Testbench
    Write-Host "  -> Compilation successful! Binary generated: $SimBinary" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Compilation failed. Check SystemVerilog syntax in top or testbench." -ForegroundColor Red
    exit 1
}

# 5. Execute Simulation with vvp
Write-Host "`n[3/4] Executing Simulation Run via vvp..." -ForegroundColor Yellow
Write-Host "----------------------------------------------------" -ForegroundColor Gray

try {
    vvp $SimBinary
    Write-Host "----------------------------------------------------" -ForegroundColor Gray
    Write-Host "  -> Simulation execution completed." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Simulation runtime error during vvp execution." -ForegroundColor Red
    exit 1
}

# 6. Check for GTKWave Waveform Dumps
Write-Host "`n[4/4] Checking for Waveform Telemetry..." -ForegroundColor Yellow
$vcdFile = Get-ChildItem -Path $RtlDir -Filter "*.vcd" | Select-Object -First 1

if ($vcdFile) {
    Write-Host "  -> Found Waveform File: $($vcdFile.Name)" -ForegroundColor Cyan
    $gtkwaveCmd = Get-Command gtkwave -ErrorAction SilentlyContinue
    if ($gtkwaveCmd) {
        Write-Host "  -> Launching GTKWave..." -ForegroundColor Green
        Start-Process gtkwave -ArgumentList $vcdFile.FullName
    } else {
        Write-Host "  -> GTKWave not detected in PATH. Waveform file available at: $($vcdFile.FullName)" -ForegroundColor Gray
    }
} else {
    Write-Host "  -> No .vcd waveform dump file generated." -ForegroundColor Gray
}

Write-Host "`n[COMPLETE] Verification script finished successfully.`n" -ForegroundColor Green
