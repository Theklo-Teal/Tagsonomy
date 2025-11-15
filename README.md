For Paracortical Initiative, 2025, Diogo "Theklo" Duarte

Other projects:
https://bsky.app/profile/diogo-duarte.bsky.social
https://diogo-duarte.itch.io/
https://github.com/Theklo-Teal

Includes the FFMpeg plugin by EIRTeam.

# DESCRIPTION
A media file organizer that allows you to associate tags to the files to then search them more easily, much like Danbooru.
This is part of my collection of projects in indefinite hiatus. I release it publicly in case someone likes the ideas and wants to develop them further or volunteers to work with me on them.
See "WHY IN HIATUS?" for more information.

# THE CONCEPT
Yeah, not much to it. I just like the idea of searching files by tag, especially when there is a collection of a lot of them and they are named poorly.
Hopefully someone makes an file explorer program that deals mainly with tags one day. Existing file explorers sometimes have tag features, but nobody remembers that or it's insuficient.

# INSTALLATION
Put these files in your Godot projects folder and search for it in project manager of Godot! Compatible with Godot 4.5.

# USAGE
Note: Some of the features mentioned are broken at the moment.
After exporting the project, there should be a "Pictures" and "Videos" folder in the same directory of the exported executable.
This is where you place your files. You can also have subfolders within for your personal organization preference. But don't puts files of the wrong type on the wrong folder.
Then you open the Database tab and add the folders you want to scan. Once you scan them, all found files will appear in the browsers.
By default all files have "untagged" tag and a tag of their file type. These are magic tags and can't be added or removed by the user. Once you add a tag to a file the "untagged" disappears.
Tags can also have aliases and be associated with other tags for easy. The auto-complete of the prompt bar at the top will help you with that.
The prompt bar has a "filter" mode that allows to select what appears in the browser, but also a "edit" mode where you can add and remove tags to a selected file.
If you click the app icon, you can see the "About" panel which includes more help information.

# WHY IN HIATUS?
There isn't any major block to the development of this application, it just requires a lot of tweaking and quality of life improvements.
The file "TODO.txt" lists known problems and desired improvements.
The more annoying thing is the feature to preview files. There's always something wrong with it.
Opening files external to the exported Godot package is always a chore, but it can deal with static pictures most of the time. Except it can't display animated GIFs.
Also the automatic scaling of pictures in the previewer is always glitching. You have to keep trying mode buttons manually to fix things.
For the longest time it was not possible to load and display video. But thanks to a recent plugin from EIRTeam, that isn't a problem anymore.
In the future enabling audio files and comic book files might be desirable, but I suspect it will be another pain in the ass.
