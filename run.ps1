param (
    [string]$ImageName = "dev-arch",
    [string]$VolumeName = "dev_workspace",
    [string]$ContainerWorkDir = "/workspace"
    )

try {
	docker info > $null 2>&1
} catch {
	Write-Host "Docker does not seem to be running. Please start Docker first." -ForegroundColor Red
	exit 1
}

$sshAgentPipe = "\\.\pipe\openssh-ssh-agent"

if (-not (Test-Path $sshAgentPipe)) {
	Write-Host "SSH agent not running. Please start 'ssh-agent' service and add your keys." -ForegroundColor Red	    exit 1
}

$volumeExists = docker volume inspect $VolumeName -ErrorAction SilentlyContinue

if (-not $volumeExists) {
	Write-Host "Docker volume '$VolumeName' does not exist. Creating..."
	docker volume create $VolumeName | Out-Null
	Write-Host "Volume created."
} else {
	Write-Host "Docker volume '$VolumeName' found."
}

docker run --rm -it `
	-v "${VolumeName}:${ContainerWorkDir}" `
	-v "${sshAgentPipe}:/ssh-agent" `
	-e "SSH_AUTH_SOCK=/ssh-agent" `
	-w "${ContainerWorkDir}" `
	$ImageName `
	fish
