$host.ui.RawUI.WindowTitle = "Powershell 6”

Remove-PSReadlineKeyHandler -Key Tab
Set-PSReadlineKeyHandler -Chord Tab -Function Complete
Set-PSReadlineKeyHandler -Function DeleteCharOrExit -Chord Ctrl+D
Set-PSReadlineOption -BellStyle None

function cdc {
	Param(
		[string]$path,
		[scriptblock]$command
	)
	$here = pwd;
	cd $path;
	try {
		& $command;
	}
 finally {
		cd $here;
	}
}