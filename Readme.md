## SnippetSync

Did you ever have the situation that you run Xcode on a clean system and all your code snippets were lost? SnippetSync is a very simple tool to sync code snippets from Xcode into a specified folder. This way your snippets are automatically backed up e.g. to Dropbox whenever you make changes to them in Xcode.

Code snippets can also be created/modified/deleted in the backup location and the changes will be synced back to the Xcode snippets folder (restart Xcode to make it recognize the changes).

Beware that this is not a full blown sync solution. It simply listens to some file system events in the given folders and attempts to copy some files back and forth.

### Launch Agent

If you want to have SnippetSync always run, you can create a Launch Agent that runs in the background and continuously listens for Xcode snippets.

Copy the launch agent plist to `~/LaunchAgents/de.kokodev.SnippetSync` and load it:

	launchctl load /Users/myuser/Library/LaunchAgents/de.kokodev.SnippetSync.plist
	launchctl start de.kokodev.SnippetSync

## Usage

	-h, --help							# Show this help
	-v, --version						# Show SnippetSync version
	-e, --extension <fileextension>		# A string to match filenames to listen for. Default: .codesnippet
	-l, --listenDir <path>				# The source snippet directory. Default: Xcode snippet folder
	-o, --outputDir <path>				# The folder to sync the snippets to. Default: Desktop
	-c, --createTarget					# If <outputDir> does not exist, create it
	-i, --initializeTarget				# Initialize the target directory with existing Xcode snippets
	-s, --copy-from-source				# Initialize source directory with existing files from the output folder
	-f, --force							# When initializing source/output directories, override files if they exist

## License

Copyright (c) 2016 kokodev.de<br/>
MIT License. See License.txt