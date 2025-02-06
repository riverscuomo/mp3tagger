# MP3 Tagger [![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://makeapullrequest.com)

A Flutter Windows app that builds filters for the Mp3Tag application. I use this script to filter my demos by various custom tags. You can easily customize the script to filter by any tag you want.

Because it's a pain to write Mp3Tag filters like this `((NOT BPM LESS 80 AND NOT BPM GREATER 100) OR (NOT BPM LESS 160 AND NOT BPM GREATER 200)) AND  (NOT %_folderpath% MATCHES solo|covers|previous|hold|szn|beats) AND  (NOT melodyStart MATCHES before) AND  (NOT Mode MATCHES mixo|mixed) AND (Melody MATCHES 3 OR Melody ABSENT) AND (FirstChord MATCHES 6 OR FirstChord ABSENT) AND  (NOT Feel MATCHES waltz|triplet) AND (Section MATCHES chorus OR Section ABSENT) AND  (NOT Section MATCHES instr|riff) AND  (NOT Masterpiece MATCHES 2|1) AND  (NOT Fall MATCHES 3) AND (Genesis MATCHES aku OR Genesis ABSENT) AND (jd MATCHES 5 OR jd ABSENT) AND (cowriter MATCHES None OR cowriter ABSENT) AND HOLD ABSENT`

Instead, set the switches in the app and click `Filter`...

![image](https://github.com/user-attachments/assets/c14141e5-ab81-4178-a4b0-6e51cf96ae9e)

... the script builds the filter string and types it into the filter  box in Mp3Tag.

![image](https://user-images.githubusercontent.com/24362267/226626980-96204111-f9d7-4793-8c2f-4d9969752954.png)


## Installation

Before you can run the `MP3 Tagger` script, there are some pre-requisites that are assumed.

### Download and install the Mp3Tag Windows Application

https://www.mp3tag.de/en/
