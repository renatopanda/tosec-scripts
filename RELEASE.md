# TOSEC - The Old School Emulation Center
This draft briefly describes the TOSEC release process. It describes the steps needed to create a new pack of datfiles merging the previous release and new wip dats.

## Procedure:
 1. unzip the last datpack to *newpack* folder
 2. get the new (wip) datfiles from the FTP to *wip* folder
	 - for instance, using the *wipftpscan.rb* script
	 - don't forget other relevant files (e.g. cue, txt)
 3. error check the new datfiles for structural errors using *datstructchecker.rb*
	- apply fixes to dats as needed to correct the errors
4. copy the new dats from *wip* to the *newpack* folder
	- place the new dats in their correct location (as in *TOSEC*, *TOSEC-ISO* or *TOSEC-PIX* folders)
5. check the entire dat collections with *datcheck.rb* to move the now outdated datfiles
	- e.g. `ruby tosec-scripts/datcheck.rb newpack/TOSEC/ > main.log`
	- the outdated datfiles will be moved to an *outdated* folder
	- *optional: check the same folders for TNC errors using the TDE tool or assume renamers did this*
6. move the new cues to the *newpack/CUEs* folder
7. check the CUEs with *cuechecker.rb* for missing and unneeded cue files
	- typical errors are:
		- unneeded cue files (for renamed sets)
		- missing cue files (new or renamer sets)
		- missing folders (renamer or new datfiles)
		- unneeded folders (renamed or removed datfiles)
		- missing and unneeded cue files due to non low-ASCII chars (if unfixable, ignore)
	- typical fixes are (manual):
		- move / remove / rename cue files or folders as needed
		- ask for any missing cue file
	- typical fixes are (auto, when lots of changes are needed):
		- use RomVault + all TOSEC-ISO dats and batch rebuild all the cue files
		- if cues are missing, generate fixdats  in RomVault and eliminate non-cue files from these fixdats using *cueonlyfixdats.rb*
		- get missing cues, rebuild them until none is missing
		- prepare them to release in its typical nonzipped format using *cueunzipper.rb*
		- replace the entire *newpack/CUEs* folder with the new CUEs
8. generate scripts to create folders and move datfiles
	- at the moment this is done with TDE + Systems XML
	- if new companies / systems are found, update Systems XML (via tosecdb) and regenerate scripts
	- test the new scripts and move them to *newpack/Scripts*
9. generate the list of changes for each collection using *diffgenerator.rb*
	- e.g.  `ruby tosec-scripts/diffgenerator.rb newpack/TOSEC/ oldpack/TOSEC/ > main-diff.log`
	- a copy of the last release pack should be available (unzipped) in *oldpack* folder
10. update *readme.txt*, including the list of changes
11. create the new zip and release it
12. statistics can be extracted with *tosecstatistics.rb*
	- e.g. `ruby tosecstatistics.rb newpack/`

### ToDo:
- update *datsstructcheck.rb* to also check for new companies and systems
	- missing from Systems XML
- create script to generate the move and create scripts instead of relying on TDE
- automate the entire process as much as possible