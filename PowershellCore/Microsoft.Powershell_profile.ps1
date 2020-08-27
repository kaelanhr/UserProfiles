# Install-Module -Name Terminal-Icons -Repository PSGallery
# Install-Module -Name BurntToast
# requires nerd font


# import modules
Import-Module DirColors
Import-Module posh-git
Import-Module oh-my-posh
Import-Module -Name Terminal-Icons

# Dir colors settings
# Update-DirColors ~\dir_colors

# oh my posh settings
$DefaultUser = 'kaela'
Set-Theme Paradox

# ps readline settings
Remove-PSReadlineKeyHandler -Key Tab
Set-PSReadlineKeyHandler -Chord Tab -Function Complete
Set-PSReadlineKeyHandler -Function DeleteCharOrExit -Chord Ctrl+D
Set-PSReadlineOption -BellStyle None
Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineOption -HistorySavePath C:\temp\history.txt
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption Colors @{Prediction = "`e[90m" }

Set-Alias sj Start-Job
Set-Alias rj Receive-Job
Set-Alias gj Get-Job

# windows terminal setting to allow ctr backspace
if ($null -ne $env:WT_SESSION ) {
	Set-PSReadLineKeyHandler -Key Ctrl+h -Function BackwardKillWord
}

# register dotnet argument completer
$scriptblock = {
	param($wordToComplete, $commandAst, $cursorPosition)
	dotnet complete --position $cursorPosition $commandAst.ToString() | ForEach-Object {
		[System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
	}
}
Register-ArgumentCompleter -Native -CommandName dotnet -ScriptBlock $scriptblock

# Creates a folder with a particular name in all sub folders.
function New-SubFolder {
	Param(
		[Parameter(Mandatory = $true)]
		[string]$folderName
	)
	Get-ChildItem -Directory | ForEach-Object {
		Push-Location $_;

		# create the directory if it does not exist.
		if (!Test-Path -Path ./$folderName) {
			mkdir $folderName
		}
	}
}

# Hard reset of database using entity framework for the project
# in the current directory.
function Reset-DatabaseEf {
	Remove-Item ./Migrations -Recurse -Force
	dotnet ef database drop
	dotnet ef migrations add Initial
	dotnet ef database update
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

if ($IsLinux) {
	# set linux command preferences
	function ex {
		xdg-open .
	}
}
elseif ($IsWindows) {
	# Set windows specific command preferences
	function ex {
		explorer .
	}
	# linux equivalent commands
	function which {
		param(
			[Parameter(Mandatory = $true)]
			[string]
			$CommandName
		)
		(Get-Command $CommandName).Path
	}
	Set-Alias ll Get-ChildItem
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

# copies the contents of a file into a new file, but without duplicated lines
function Remove-Duplicates {
	param (
		[Parameter(Mandatory = $true)]
		[string]
		$Filepath
	)
	$FileObject = Get-ChildItem $FilePath
	(Get-Content $FilePath | Select-Object -Unique) > "$($FileObject.Name)-NoDuplicates.txt"
}

if ($IsLinux) {
	function Set-Theme {
		param (
			[Parameter(Mandatory)]
			[ValidateSet('Dark', 'Light')]
			[string]
			$Theme
		)
		if ($Theme -eq "Dark") {
			gsettings set org.gnome.desktop.interface gtk-theme "Yaru-dark"
		}
		if ($Theme -eq "Light") {
			gsettings set org.gnome.desktop.interface gtk-theme "Yaru"
		}
	}
}
