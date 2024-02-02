# Import modules
Import-Module DirColors
Import-Module oh-my-posh
Import-Module posh-git
Import-Module -Name Terminal-Icons
Import-Module z

# Dir colors settings
# Update-DirColors ~\dir_colors

# requires nerd font
# oh my posh settings
# oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\jandedobbeleer.omp.json" | Invoke-Expression

# PS Readline settings
Remove-PSReadlineKeyHandler -Key Tab
Set-PSReadlineKeyHandler -Chord Tab -Function Complete
Set-PSReadlineKeyHandler -Function DeleteCharOrExit -Chord Ctrl+D
Set-PSReadlineOption -BellStyle None
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineOption -HistorySavePath C:\temp\history.txt
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{InlinePrediction = "`e[90m" }

# Base Alias'
Set-Alias ll Get-ChildItem

# register dotnet argument completer
$scriptblock = {
	param($wordToComplete, $commandAst, $cursorPosition)
	dotnet complete --position $cursorPosition $commandAst.ToString() | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

# Functions
function Get-Uuid {
	([guid]::newguid()).Guid | clip
}
Set-Alias guid Get-Uuid

function Open-Explorer {
	[CmdletBinding()]
	Param(
		[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]$Path = '.'
	)
	# If we are a file in a folder then get the containing folder
	if (-not (Get-Item $Path).PSIscontainer) {
		$Path = Get-ParentDirectory $Path
	}

	if ($IsLinux) {
		xdg-open .
	}
	elseif ($IsWindows) {
		explorer $Path
	}
}
Set-Alias ex Open-Explorer

function which {
	param(
		[Parameter(Mandatory = $true)]
		[string]
		$CommandName
	)
	(Get-Command $CommandName).Path
}

function m2d() {
	[CmdletBinding()]
	Param(
		[Parameter(Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)][String]$Path,
		[Parameter()][switch]$PassThru,
		[Parameter(Position = 1, Mandatory = $false)][switch]$Open
	)
	$Params = @{
		Path     = $Path
		PassThru = $PassThru
	}

	Set-Location @Params
	if ($Open) { explorer . }
}

# navigate to a location, execute a command and navigate back.
function cdc {
	Param(
		[string]$path,
		[scriptblock]$command
	)
	$here = Get-Location;
	Set-Location $path;
	try {
		& $command;
	}
 finally {
		Set-Location $here;
	}
}

function Invoke-GitCommit() {
	[CmdletBinding()]
	Param(
		[Parameter(Position = 0)][string]$commitMessage
	)
	git commit -m "[$(Get-GitBranch)] $commitMessage"
}

function Invoke-GitPushBranch {
	git push --set-upstream origin $(Get-GitBranch)
}

function Invoke-SubProjectsCommand() {
	Param(
		[scriptblock]$command
	)
	Get-ChildItem -Directory | ForEach-Object {
		if (Test-Path $_/.git -PathType Container) {
			Write-Host $_.Name -ForegroundColor Green
			Write-Host $_.Name
			cdc $_ $command
		}
	}
}

function Invoke-PullSubProjects() {
	Invoke-SubProjectsCommand {
		git pull
	}
}

function Get-ChildBranches() {
	Invoke-SubProjectsCommand {
		git branch | Select-String "\*"
	}
}
function Set-ChildBranches() {
	param (
		[Parameter(Mandatory)]
		[string]
		$branchName
	)
	Invoke-SubProjectsCommand {
		Write-Host "Setting ${$_.Name} to $branchName" -ForegroundColor Green
		git checkout $branchName
	}
}
