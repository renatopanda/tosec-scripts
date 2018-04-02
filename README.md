# TOSEC - The Old School Emulation Center
A set of small simple Ruby scripts used to manage TOSEC datfiles.

## datcheck.rb
Checks a folder for outdated TOSEC datfiles based on version in filename or dats nested in others.

WIP dats can be placed in the current release folder, the script will move the outdated ones to "outdated" folder. Dats with nested categories* are not moved, only listed.

 *- Dats split in two or more new ones with deeper categories, for instance: "XXX - Games" and "XXX - Games - [BIN]".

### Usage
```
$ ruby datcheck.rb
Usage: ruby datcheck.rb [dats_folder]
Example: ruby datcheck.rb newpack/TOSEC/
```
### Example
```
$ ruby datcheck.rb newpack/TOSEC/
-------------------------
Found unremoved updates:
Acorn Atom - Games - [DSK] (TOSEC-v2017-07-05_CM).dat
Acorn Atom - Games - [DSK] (TOSEC-v2018-03-08_CM).dat
Moved files:
newpack/TOSEC/Acorn Atom - Games - [DSK] (TOSEC-v2017-07-05_CM).dat
-------------------------
Possible problem with a category placed inside a terminal category
Casio Loopy - Games - Multipart (TOSEC-v2018-03-08_CM).dat
Casio Loopy - Games - [BIN] (TOSEC-v2018-03-08_CM).dat
-------------------------
(...)
Moved 301 datfiles.
Possible problems: 8.
```

---

## diffgenerator.rb
Generates a list of differences (new/updated/removed) between two folders with TOSEC datfiles.
Used to create the descriptions at the end of README.txt of each release.

### Usage
```
$ ruby diffgenerator.rb
Usage: ruby diffgenerator.rb [newfolder] [oldfolder]
Example: ruby diffgenerator.rb newpack/TOSEC/ oldpack/TOSEC/
```
### Example
```
$ ruby diffgenerator.rb newpack/TOSEC/ oldpack/TOSEC/
Generate new/updated/removed between folders.
Newer folder: newpack/TOSEC-ISO/
Older folder: oldpack/TOSEC-ISO/
--------------------
Added: 39
Updated: 13
Removed: 13
Problems: 0
--------------------
newpack/TOSEC-ISO/: 204 DATs (39 new / 13 updated / 13 removed)

NEW (39):
Commodore Amiga - CD - Applications - [IMG] (TOSEC-v2018-03-24_CM).dat
Commodore Amiga - CD - Applications - [ISO] (TOSEC-v2018-03-25_CM).dat
(...)

UPDATED (13):
3DO 3DO Interactive Multiplayer - Games (TOSEC-v2018-03-23_CM).dat
Commodore Amiga - CD - Operating Systems (TOSEC-v2018-03-24_CM).dat
(...)

REMOVED (13):
Commodore Amiga - CD - Applications (TOSEC-v2017-10-23_CM).dat
Commodore Amiga - CD - Compilations (TOSEC-v2017-10-23_CM).dat
(...)
```

---

## tosecstatistics.rb
Extracts global statistics from a folder containing the 3 TOSEC branches (1 per folder).

### Usage
```
$ ruby tosecstatistics.rb
Usage: ruby tosecstatistics.rb [packfolder]
Example: ruby tosecstatistics.rb newpack/
```
### Example
```
$ ruby ruby tosecstatistics.rb newpack/
Acorn Archimedes - Applications (TOSEC-v2013-10-16_CM).dat: sets=12 / roms=12 / size=8.92 MiB / size[SI]=9.35 MB
Acorn Archimedes - Compilations - Games - [JFD] (TOSEC-v2017-07-05_CM).dat: sets=13 / roms=13 / size=214.80 KiB / size[SI]=219.95 kB
(...)
-------------------------------------------
----------- Datfiles Statistics -----------
-------------------------------------------
-TOSEC-main--------------------------------
Datfiles: 1714
Setfiles: 753545
Romfiles: 834966
Size: 261.07 GiB (280320283624.0 bytes)
Size: 280.32 GB (280320283624.0 bytes)
-------------------------------------------
(...)
-TOSEC-total--------------------------------
Datfiles: 2738
Setfiles: 785337
Romfiles: 902029
Size: 4.91 TiB (5395494297143.0 bytes)
Size: 5.40 TB (5395494297143.0 bytes)
-------------------------------------------
```

---

## CUE Files' Scripts
A bunch of scripts used to check and prepare the cue files included in each release. They serve to
1) check the consistency between dat information and available cues
2) unzip all the cues and remove empty folders
3) remove all noncue roms from fixdats to get the missing ones before a release

Typical usage is to check if something is missing with `cuechecker.rb`. If yes, rebuild all cues with RomVault or clrmame pro, then generate fixdats. Since the fixdats will contain the isos and bin, strip all that with `cueonlyfixdats.rb`. Ask for the remaining cues, rebuild and then use `cueunzipper.rb` (since they have always been distributed that way). Check again with `cuechecker.rb` if needed.

### cuechecker.rb usage
```
$ ruby cuechecker.rb
Usage: ruby cuechecker.rb [datsfolder] [cuesbasefolder]
Example: ruby cuechecker.rb newpack/TOSEC-ISO/ newpack/CUEs/
```

### cueonlyfixdats.rb usage
```
$ ruby cueonlyfixdats.rb
Usage: ruby cueonlyfixdats.rb [fixdats_folder]
Example: ruby cueonlyfixdats.rb fixdats/
```

### cueunzipper.rb usage
```
$ ruby cueunzipper.rb
Usage: ruby cueunzipper.rb [cuesbasefolder]
Example: ruby cueunzipper.rb newpack/CUEs/
```
