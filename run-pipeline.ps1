[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$Environment = "hub",

    [Parameter(Mandatory=$false)]
    [switch]$EnforceSecurity
)

# This tells the script to instantly fail the ADO pipeline if any command fails
$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "🚀 TERRAFORM CI PIPELINE: $($Environment.ToUpper())" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$TF_DIR = "terraform/environments/$Environment"

if (-Not (Test-Path $TF_DIR)) {
    Write-Error "Environment directory '$TF_DIR' does not exist!"
    exit 1
}

Write-Host "`n▶ STEP 1: Running Security Scan (Checkov)" -ForegroundColor Yellow
if ($EnforceSecurity) {
    Write-Host "Running in STRICT mode. ADO Build will fail if vulnerabilities are found." -ForegroundColor Gray
    checkov -d $TF_DIR
} else {
    Write-Host "Running in AUDIT mode (--soft-fail). Security alerts will not crash the build." -ForegroundColor Gray
    checkov -d $TF_DIR --soft-fail
}

Write-Host "`n▶ STEP 2: Initializing Terraform" -ForegroundColor Yellow
Set-Location -Path $TF_DIR
terraform init -upgrade

Write-Host "`n▶ STEP 3: Checking Terraform Formatting & Syntax" -ForegroundColor Yellow
terraform fmt -check
terraform validate

Write-Host "`n▶ STEP 4: Generating Infrastructure Plan (Artifact)" -ForegroundColor Yellow
# We space out the arguments properly for PowerShell and ADO agents
terraform plan -out main.tfplan

Write-Host "`n✅ PIPELINE RUN COMPLETE FOR: $($Environment.ToUpper())" -ForegroundColor Green
