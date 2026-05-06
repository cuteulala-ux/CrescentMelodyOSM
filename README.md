# CrescentMelodyOSM
Brings Midi Support To Opensim

DO NOT FOLLOW INSTRUTIONS HERE ITS CONFUSING READ THE Instructions.txt downloaded. 

CrescentMelodyOSM for OpenSim is the result of 17 years of musical passion and hard work to get to were it is now.. As you can
imagine the work put into it for it to become a freebie! :)
If you enjoy the software please consider donating to winxtropia@gmail.com On Paypal

For Updates And The only place to ask questions for this plugin is through my discord channel Winxtropia. https://discord.gg/5NfaFPnWV
REMEMBER AS PART OF THE LISCENSE I WILL NOT PROVIDE SUPPORT BUT TO ONLY HELP YOU GET IT WORKING! 

An OAR is Provided! With The Controller And Entire Midi Kit System.

!!GET THE OAR FROM MY DISCORD CHANNEL!! Click the CrescentMelodyOSM channel in the pinned comment.


CrescentMelodyOSM for OpenSim

Created by Bloom Peters (Winxtropia)

What is in this folder
- OpenSim.Region.OptionalModules.CrescentMelodyOSM.dll
- OpenSim.Region.OptionalModules.CrescentMelodyOSM.addin.xml

Before you install
- OpenSimulator region server running on .NET 8.
- Access to the region's INI files.
- You must be able to restart the region.
- Setting PROPER Timers and OSSL Settings CRITICAL
Inside Opensim.ini find the sections and add.
-----------------------------------------------------------------------------------------
[YEngine]
    ScriptHeapSize = 3072

    MinTimerInterval = 0.02
    AsyncLLCommandLoopms = 15


[OSSL]
    Include-osslDefaultEnable = "config-include/osslDefaultEnable.ini"
    OSFunctionThreatLevel = VeryHigh
    Allow_osConsoleCommand = GRID_GOD,ESTATE_OWNER,7a3d92e4-6f8b-4c21-b5a9-2d7e0f1c9ab3

[CrescentMelodyOSM]
Enabled = true
PipeName = CrescentMelodyOSM
EmitLegacyNumeric = true
LegacyChannelMode = fullstudio
NoteOutputOffset = -20
ChannelOutputOffset = 1
QuantizeMs = 0

-------------------------------------------------------------------------------------------

osConsoleCommand-NOTE DO NOT DO NOT MAKE THIS PUBLIC! ADD THE OWNER UIID. Example UIID not mine. 


Important security notes
- The module only runs when the region's effective OSSL threat level is VeryHigh.
- If you use osConsoleCommand from scripts, make sure Allow_osConsoleCommand includes the users/roles you allow.
- After OSSL changes, reset the script if OpenSim says it is required.
- If midi commands show Invalid command after install, stop the region, delete bin\addin-db-004, then start the region again so the addon cache rebuilds.


4) In OSSL config, make sure this region effectively uses VeryHigh threat level.
5) In the region bin folder, create a folder named: Midi
6) Put your MIDI files inside:
   Midi\*.mid (or .midi)
7) If present, delete cache folder but only once!:
   addin-db-004 
8) Start the region again.

First run behavior
- It automatically preloads MIDI #1 from the Midi folder. than uses no cpu at all until commanded to. 
- It sends an alert when a song is loaded/ready.
- When a song ends, it auto-selects the next one and announces ready.
- If new MIDI files are added to the region's Midi folder, the next list/select/next/prev refresh picks them up automatically. No folder monitor is required.
- Speed memory is stored per MIDI file in `Midi\speed-settings.json`.
- When you change speed, that MIDI file's speed setting is saved immediately.
- Switching to another MIDI resets to that MIDI's saved speed if one exists, otherwise normal speed.

Quick check
- In region console: midi status
- You should also see this startup line in logs:
  Created By Bloom Peters From Winxtropia With Love For Opensim! (Not to be removed from the plugin) 

Install Midi
- `dl <url>` downloads a `.mid` file from the internet into the region `Midi` folder.
- Only `https` URLs are allowed.
- The URL must end in `.mid` or it is rejected.
- Downloaded files are rejected unless they begin with the MIDI header `MThd`.
- Downloaded files are rejected if they exceed `100 KB`.
- After download, the MIDI library is refreshed automatically.
- A successful download also loads that MIDI as the current selection immediately, ready for `Play`, but it does not auto-start playback.

Delete Midis
- `del` deletes the currently loaded MIDI file from the region `Midi` folder.
- If another MIDI is available, the DLL selects the next available one without auto-playing it.
- The included touch controller exposes this through an owner-only `Del` button with confirmation.


Limitations
- OpenSim timing is step-based, not sample-accurate audio timing.
- Playback is quantized into time steps, so tiny MIDI timing differences are approximated.
- Very dense or very fast MIDI passages can sound slightly early/late or uneven.
- Depending on sim load, some files may run a bit faster/slower than intended.
- Region CPU/script/frame load affects playback stability.


At this point you are DONE and the plugin should work! And you can load the oar and play with it but..

This here is not needed since the OAR has the controller already!! You can Skip this but if you want to control it on the console here are the commands. 
Commands
- The region announces the currently playing MIDI file in an alert message.
- midi status
- midi mode 1
- midi mode 2
- midi list
- dl <https://example.com/file.mid>
- del
- midi <number>                 (example: midi 1)
- midi select <number>
- midisel <number>
- select midi <number>
- midi next
- midi prev
- midi first
- midi last
- midi play
- midi pause
- midi resume
- midi stop
- midi seek <milliseconds>
- midi speed+
- midi speed-
- midi speedplus
- midi speedminus
- midi load "FULL_PATH_TO_FILE.mid" [tempoScale]
- midi blast <channel> <message>
