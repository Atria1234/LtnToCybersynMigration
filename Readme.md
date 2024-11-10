Mod which attempts to migrate from LTN to Project Cybersyn.

# Requirements

- [LogisticTrainNetwork](https://mods.factorio.com/mod/LogisticTrainNetwork) mod was used in Factorio 1.1
- [LTN Combinator Modernized](https://mods.factorio.com/mod/LTN_Combinator_Modernized) mod was used in Factorio 1.1 to configure stations
- [LTN Combinator Modernized](https://mods.factorio.com/mod/LTN_Combinator_Modernized)'s combinators were directly connected to LTN station input lamp

# What this mod does

The mod adds two shortcuts ("Migrate stations" and "Toggle trains") which run the two migration steps.

## Migrate stations

When "Migrate stations" is clicked, it first check every LTN stations on all surfaces if they satisfy all conditions:

- LTN station input lamp is found within 2x2 box around the station
- LTN station output combinator is found within 2x2 box around the station
- LTN combinator is found on same circuit network as LTN station input lamp (both networks are checked)
- There is 2x1 free place for Cybersyn combinator around the station

GPS link is printed into ingame console for each station which doesn't satisfy any of these conditions.

Then for each station which satisfies all conditions it does:
- Replaces LTN train station with Vanilla train station
    - Sets train station's "trains limit" to whatever was configured in LTN combinator
- Replaces LTN combinator with Vanilla constant combinator
    - Separates control and request signals into two sections
    - Sets value of "A" virtual signal (used to set Network ID) from Network ID of LTN combinator
    - Sets value of "Station priority" virtual signal from Requester/Provider priority of LTN combinator
    - Sets value of "Request threshold" virtual signal from Request (or stack) threshold of LTN combinator if station is requester
    - Sets value of "Locked slots" virtual signal from Locked slots of LTN combinator
- Creates Cybersyn combinator in closest free space around the station (free of charge)
    - Sets network ID to "A" virtual signal
    - Enables station as requester if LTN combinator had requester threshold configured
        - Enables "Stack thresholds" if LTN combinator used stack threshold instead of simple threshold
    - Enables station as provider if LTN combinator had provider threshold configured
        - Enables "Inactivity condition" if mod setting was enabled
    - Enables station as depot if LTN combinator has depot configured
        - Enables "Same depot" if mod setting was enabled
        - Enables "Bypass depot" if mod setting was enabled
- Connects all entities connected to LTN station input lamp to input of Cybersyn combinator
- Connects all entities connected to LTN station output combinator to output of Cybersyn combinator
- Deletes LTN station input lamp
- Deletes LTN station output combinator

# Migration steps

## Preparation in Factorio 1.1

- Disable LTN dispatcher
    - Wait for all trains to return to depot
- Save

## Steps in Factorio 2.0

- Disable LTN mod (trivial, since it doesn't work on Factorio 2.0)
- Disable LTN combinator mod (trivial, since it doesn't work on Factorio 2.0)
- Enable this mod
- Load save
- Click on "Migrate stations" shortcut (doesn't touch already migrated stations, so it can be used multiple times)
    - Either
        - Fix stations which failed to migrate manually
        - Give up and keep playing on Factorio 1.1
        - Ask LTN's mod author for permission to update LTN to 2.0 yourself
        - Report on Github your use case and maybe I will be able to update the mod to support your use case (include your save file for testing)
- Click on "Toggle trains" shortcut
    - Cybersyn should start scheduling trains after a second
- Save as different savefile (just to be sure)
- Disable this mod
- Load save and continue on Cybersyn
    - Observe for some time to see if there are any problems

# Limitations

- Mod can't migrate LTN's min train length config
- Mod can't migrate LTN's max train length config
- Mod can't migrate LTN's depot priority config
- Cybersyn doesn't support provider threshold
