// CrescentMelodyOSM Touch Controller
// Buttons: Play, Pause, Stop, Resume, Next, Prev, Speed+, Speed-, Continuous, Install, Del, Search, Favorites, Midi Mode 1, Midi Mode 2
// Requires OSSL osConsoleCommand permission for script owner.

integer selectedSongIndex = 1;
integer INPUT_CH;
integer inputHandle;
integer CONFIRM_CH;
integer confirmHandle;
integer SEARCH_INPUT_CH;
integer searchInputHandle;
integer SEARCH_DIALOG_CH;
integer searchDialogHandle;
integer FAV_DIALOG_CH;
integer favDialogHandle;
integer SEARCH_RESULT_CH = 9088;
integer searchResultHandle;
key inputUser = NULL_KEY;
key confirmUser = NULL_KEY;
key searchUser = NULL_KEY;
integer searchPage = 0;
integer searchPerPage = 9;
integer searchTotal = 0;
list searchNames = [];
key favoritesUser = NULL_KEY;
integer favoritesPage = 0;
integer favoritesPerPage = 9;
integer favoritesTotal = 0;
list favoriteNames = [];
integer favoritesDeleteMode = FALSE;
integer favoritesPlayMode = FALSE;
string currentMidiName = "";

list INSTALL_WHITELIST = [
    "534fe8f4-f32d-485e-8313-5e10186b0d72"
];

vector COLOR_WHITE = <1.0, 1.0, 1.0>;
vector COLOR_GREEN = <0.0, 1.0, 0.0>;
vector COLOR_RED = <1.0, 0.0, 0.0>;
vector COLOR_FLASH = <1.0, 1.0, 0.0>;
vector COLOR_MODE = <0.0, 0.6, 1.0>;
float FLASH_SECONDS = 0.5;

list flashLinks = [];
list flashUntil = [];
integer playLink = -1;
integer mode1Link = -1;
integer mode2Link = -1;
integer continuousLink = -1;
integer activeMode = 1;
integer continuousEnabled = FALSE;

sendCmd(string cmd) { osConsoleCommand(cmd); }

setButtonColor(integer linkNum, vector color) { if (linkNum > 0) llSetLinkColor(linkNum, color, ALL_SIDES); }

integer findLinkByName(string primName)
{
    integer count = llGetNumberOfPrims();
    integer linkNum;
    for (linkNum = 1; linkNum <= count; ++linkNum)
    {
        if (llToLower(llGetLinkName(linkNum)) == llToLower(primName)) return linkNum;
    }
    return -1;
}

integer findFlashIndex(integer linkNum) { return llListFindList(flashLinks, [linkNum]); }

updateFlashTimer() { if (llGetListLength(flashLinks) > 0) llSetTimerEvent(0.1); else llSetTimerEvent(0.0); }

flashButton(integer linkNum)
{
    if (linkNum <= 0) return;
    integer idx = findFlashIndex(linkNum);
    float until = llGetTime() + FLASH_SECONDS;
    if (idx >= 0) flashUntil = llListReplaceList(flashUntil, [until], idx, idx);
    else { flashLinks += [linkNum]; flashUntil += [until]; }
    setButtonColor(linkNum, COLOR_FLASH);
    updateFlashTimer();
}

setPlayActive(integer isActive)
{
    if (playLink == -1) playLink = findLinkByName("Play");
    if (playLink != -1) setButtonColor(playLink, isActive ? COLOR_GREEN : COLOR_WHITE);
}

resetNamedButtons()
{
    list names = ["Play", "Pause", "Stop", "Resume", "Next", "Prev", "Speed+", "Speed +", "Speed-", "Speed -", "Continuous", "Install", "Del", "Search", "Favorites", "Midi Mode 1", "Midi Mode 2"];
    integer i;
    for (i = 0; i < llGetListLength(names); ++i)
    {
        integer linkNum = findLinkByName(llList2String(names, i));
        if (linkNum != -1) setButtonColor(linkNum, COLOR_WHITE);
    }
}

setContinuousActive(integer isActive)
{
    continuousEnabled = isActive;
    if (continuousLink == -1) continuousLink = findLinkByName("Continuous");
    if (continuousLink != -1) setButtonColor(continuousLink, continuousEnabled ? COLOR_GREEN : COLOR_RED);
}

setModeActive(integer modeValue)
{
    activeMode = modeValue;
    if (mode1Link == -1) mode1Link = findLinkByName("Midi Mode 1");
    if (mode2Link == -1) mode2Link = findLinkByName("Midi Mode 2");
    if (mode1Link != -1) setButtonColor(mode1Link, (activeMode == 1) ? COLOR_MODE : COLOR_WHITE);
    if (mode2Link != -1) setButtonColor(mode2Link, (activeMode == 2) ? COLOR_MODE : COLOR_WHITE);
}

selectSong(integer idx)
{
    if (idx < 1) idx = 1;
    selectedSongIndex = idx;
    sendCmd("midisel " + (string)selectedSongIndex);
    sendCmd("midi play");
    setPlayActive(TRUE);
}

integer canUseInstall(key userId)
{
    if (userId == llGetOwner()) return TRUE;
    if (llListFindList(INSTALL_WHITELIST, [(string)userId]) != -1) return TRUE;
    return FALSE;
}

showInstallInput(key userId) { inputUser = userId; llTextBox(userId, "Paste MIDI URL (.mid only):", INPUT_CH); }
showDeleteConfirm(key userId) { confirmUser = userId; llDialog(userId, "Delete the currently loaded MIDI file?", ["Delete", "Cancel"], CONFIRM_CH); }
showSearchInput(key userId) { searchUser = userId; llTextBox(userId, "Search MIDI name (example: cu):", SEARCH_INPUT_CH); }

showSearchPage()
{
    if (searchUser == NULL_KEY) return;
    integer total = llGetListLength(searchNames);
    if (total <= 0)
    {
        llOwnerSay("Search found no results.");
        return;
    }

    integer totalPages = (total + searchPerPage - 1) / searchPerPage;
    if (searchPage < 0) searchPage = 0;
    if (searchPage >= totalPages) searchPage = totalPages - 1;

    integer start = searchPage * searchPerPage;
    integer end = start + searchPerPage - 1;
    if (end >= total) end = total - 1;

    list buttons = [];
    string body = "Search Results (Page " + (string)(searchPage + 1) + "/" + (string)totalPages + ")\n";
    integer i;
    for (i = start; i <= end; ++i)
    {
        integer num = i + 1;
        buttons += [(string)num];
        body += (string)num + ". " + llList2String(searchNames, i) + "\n";
    }
    if (searchPage > 0) buttons += ["Prev"];
    if ((searchPage + 1) < totalPages) buttons += ["Next"];
    buttons += ["Close"];
    llDialog(searchUser, body, buttons, SEARCH_DIALOG_CH);
}

clearSearchState()
{
    searchNames = [];
    searchTotal = 0;
    searchPage = 0;
}

clearFavoritesState()
{
    favoriteNames = [];
    favoritesTotal = 0;
    favoritesPage = 0;
    favoritesDeleteMode = FALSE;
    favoritesPlayMode = FALSE;
}

clearFavoritesListOnly()
{
    favoriteNames = [];
    favoritesTotal = 0;
    favoritesPage = 0;
}

showFavoritesActionDialog(key userId)
{
    favoritesUser = userId;
    llDialog(userId, "Favorites Options", ["Favorites", "Add", "Del"], FAV_DIALOG_CH);
}

showFavoritesPage()
{
    if (favoritesUser == NULL_KEY) return;
    integer total = llGetListLength(favoriteNames);
    if (total <= 0)
    {
        llOwnerSay("No favorites yet.");
        return;
    }

    integer totalPages = (total + favoritesPerPage - 1) / favoritesPerPage;
    if (favoritesPage < 0) favoritesPage = 0;
    if (favoritesPage >= totalPages) favoritesPage = totalPages - 1;

    integer start = favoritesPage * favoritesPerPage;
    integer end = start + favoritesPerPage - 1;
    if (end >= total) end = total - 1;

    list buttons = [];
    string body = "";
    if (favoritesDeleteMode) body = "DELETE FAVORITE (This does NOT delete MIDI file)\n";
    else body = "My Favorites\n";
    body += "Page " + (string)(favoritesPage + 1) + "/" + (string)totalPages + "\n";
    integer i;
    for (i = start; i <= end; ++i)
    {
        integer num = i + 1;
        buttons += [(string)num];
        body += (string)num + ". " + llList2String(favoriteNames, i) + "\n";
    }
    if (favoritesPage > 0) buttons += ["Prev"];
    if ((favoritesPage + 1) < totalPages) buttons += ["Next"];
    buttons += ["Close"];
    llDialog(favoritesUser, body, buttons, FAV_DIALOG_CH);
}

handleTouchedButton(integer linkNum, string primName)
{
    string lowerName = llToLower(primName);

    if (lowerName == "play") { sendCmd("midi play"); setPlayActive(TRUE); return; }
    if (lowerName == "stop") { sendCmd("midi stop"); setContinuousActive(FALSE); setPlayActive(FALSE); setButtonColor(linkNum, COLOR_WHITE); return; }
    if (lowerName == "pause")
    {
        sendCmd("midi pause");
        flashButton(linkNum);
        if (playLink == -1) playLink = findLinkByName("Play");
        if (playLink != -1) setButtonColor(playLink, COLOR_FLASH);
        return;
    }
    if (lowerName == "resume")
    {
        sendCmd("midi resume");
        flashButton(linkNum);
        return;
    }
    if (lowerName == "continuous")
    {
        if (continuousEnabled) sendCmd("midi continuousoff");
        else sendCmd("midi continuouson");
        setContinuousActive(!continuousEnabled);
        return;
    }
    if (lowerName == "next") { flashButton(linkNum); sendCmd("midi next"); sendCmd("midi play"); setPlayActive(TRUE); return; }
    if (lowerName == "prev") { flashButton(linkNum); sendCmd("midi prev"); sendCmd("midi play"); setPlayActive(TRUE); return; }
    if (lowerName == "speed+" || lowerName == "speed +" || lowerName == "speedplus") { sendCmd("midi speedplus"); flashButton(linkNum); return; }
    if (lowerName == "speed-" || lowerName == "speed -" || lowerName == "speedminus") { sendCmd("midi speedminus"); flashButton(linkNum); return; }
    if (lowerName == "midi mode 1") { sendCmd("midi mode 1"); setModeActive(1); return; }
    if (lowerName == "midi mode 2") { sendCmd("midi mode 2"); setModeActive(2); return; }
}

default
{
    state_entry()
    {
        INPUT_CH = -1000000 - (integer)llFrand(1000000.0);
        CONFIRM_CH = -2000000 - (integer)llFrand(1000000.0);
        SEARCH_INPUT_CH = -3000000 - (integer)llFrand(1000000.0);
        SEARCH_DIALOG_CH = -4000000 - (integer)llFrand(1000000.0);
        FAV_DIALOG_CH = -5000000 - (integer)llFrand(1000000.0);
        if (inputHandle) llListenRemove(inputHandle);
        if (confirmHandle) llListenRemove(confirmHandle);
        if (searchInputHandle) llListenRemove(searchInputHandle);
        if (searchDialogHandle) llListenRemove(searchDialogHandle);
        if (favDialogHandle) llListenRemove(favDialogHandle);
        if (searchResultHandle) llListenRemove(searchResultHandle);
        inputHandle = llListen(INPUT_CH, "", "", "");
        confirmHandle = llListen(CONFIRM_CH, "", "", "");
        searchInputHandle = llListen(SEARCH_INPUT_CH, "", "", "");
        searchDialogHandle = llListen(SEARCH_DIALOG_CH, "", "", "");
        favDialogHandle = llListen(FAV_DIALOG_CH, "", "", "");
        searchResultHandle = llListen(SEARCH_RESULT_CH, "", "", "");
        playLink = findLinkByName("Play");
        mode1Link = findLinkByName("Midi Mode 1");
        mode2Link = findLinkByName("Midi Mode 2");
        continuousLink = findLinkByName("Continuous");
        flashLinks = [];
        flashUntil = [];
        clearSearchState();
        resetNamedButtons();
        setPlayActive(FALSE);
        setContinuousActive(FALSE);
        setModeActive(1);
        llSetTimerEvent(0.0);
    }

    on_rez(integer p) { llResetScript(); }
    changed(integer change) { if (change & CHANGED_LINK) llResetScript(); }

    touch_start(integer total)
    {
        integer i;
        for (i = 0; i < total; ++i)
        {
            integer linkNum = llDetectedLinkNumber(i);
            string primName = llGetLinkName(linkNum);
            string lowerName = llToLower(primName);
            key toucher = llDetectedKey(i);

            if (lowerName == "install")
            {
                if (canUseInstall(toucher)) { flashButton(linkNum); showInstallInput(toucher); }
            }
            else if (lowerName == "del")
            {
                if (toucher == llGetOwner()) { flashButton(linkNum); showDeleteConfirm(toucher); }
            }
            else if (lowerName == "search")
            {
                flashButton(linkNum);
                clearSearchState();
                showSearchInput(toucher);
            }
            else if (lowerName == "favorites")
            {
                if (toucher == llGetOwner())
                {
                    flashButton(linkNum);
                    showFavoritesActionDialog(toucher);
                }
            }
            else
            {
                handleTouchedButton(linkNum, primName);
            }
        }
    }

    listen(integer channel, string name, key id, string msg)
    {
        if (channel == INPUT_CH)
        {
            if (id != inputUser) return;
            msg = llStringTrim(msg, STRING_TRIM);
            if (msg != "") sendCmd("dl " + msg);
            inputUser = NULL_KEY;
            return;
        }

        if (channel == CONFIRM_CH)
        {
            if (id != confirmUser) return;
            if (msg == "Delete") sendCmd("del");
            confirmUser = NULL_KEY;
            return;
        }

        if (channel == SEARCH_INPUT_CH)
        {
            if (id != searchUser) return;
            msg = llStringTrim(msg, STRING_TRIM);
            clearSearchState();
            if (msg != "") sendCmd("search " + msg);
            return;
        }

        if (channel == SEARCH_DIALOG_CH)
        {
            if (id == searchUser)
            {
                if (msg == "Prev") { searchPage -= 1; showSearchPage(); return; }
                if (msg == "Next") { searchPage += 1; showSearchPage(); return; }
                if (msg == "Close") { clearSearchState(); return; }

                integer pick = (integer)msg;
                if (pick >= 1 && pick <= llGetListLength(searchNames))
                {
                    currentMidiName = llList2String(searchNames, pick - 1);
                    sendCmd("searchselect " + (string)pick);
                    setPlayActive(TRUE);
                    clearSearchState();
                }
                return;
            }
            return;
        }

        if (channel == FAV_DIALOG_CH)
        {
            if (id != favoritesUser) return;
            if (msg == "Add")
            {
                sendCmd("faveadd");
                if (currentMidiName != "") llOwnerSay("Added " + currentMidiName + " to Favorites!");
                else llOwnerSay("Added current MIDI to Favorites!");
                return;
            }
            if (msg == "Del")
            {
                clearFavoritesListOnly();
                favoritesPlayMode = FALSE;
                favoritesDeleteMode = TRUE;
                sendCmd("favelist");
                return;
            }
            if (msg == "Favorites")
            {
                clearFavoritesListOnly();
                favoritesDeleteMode = FALSE;
                favoritesPlayMode = TRUE;
                sendCmd("favelist");
                return;
            }
            if (msg == "Prev") { favoritesPage -= 1; showFavoritesPage(); return; }
            if (msg == "Next") { favoritesPage += 1; showFavoritesPage(); return; }
            if (msg == "Close") { clearFavoritesState(); return; }

            integer favePick = (integer)msg;
            if (favePick >= 1 && favePick <= llGetListLength(favoriteNames))
            {
                if (favoritesDeleteMode) sendCmd("favedelete " + (string)favePick);
                else if (favoritesPlayMode)
                {
                    currentMidiName = llList2String(favoriteNames, favePick - 1);
                    sendCmd("faveselect " + (string)favePick);
                    setPlayActive(TRUE);
                }
                clearFavoritesState();
            }
            return;
        }

        if (channel == SEARCH_RESULT_CH)
        {
            list p = llParseStringKeepNulls(msg, ["|"], []);
            if (llGetListLength(p) < 2) return;
            string prefix = llList2String(p, 0);
            if (prefix == "CMSEARCH")
            {
                string kind = llList2String(p, 1);
                if (kind == "START")
                {
                    clearSearchState();
                    if (llGetListLength(p) >= 4) searchTotal = (integer)llList2String(p, 3);
                    return;
                }
                if (kind == "ITEM")
                {
                    if (llGetListLength(p) >= 5) searchNames += [llList2String(p, 4)];
                    return;
                }
                if (kind == "END")
                {
                    if (llGetListLength(searchNames) > 0) showSearchPage();
                    else llOwnerSay("Search found no results.");
                    return;
                }
            }
            else if (prefix == "CMFAV")
            {
                string k2 = llList2String(p, 1);
                if (k2 == "START")
                {
                    clearFavoritesListOnly();
                    if (llGetListLength(p) >= 3) favoritesTotal = (integer)llList2String(p, 2);
                    return;
                }
                if (k2 == "ITEM")
                {
                    if (llGetListLength(p) >= 4) favoriteNames += [llList2String(p, 3)];
                    return;
                }
                if (k2 == "END")
                {
                    if (llGetListLength(favoriteNames) > 0) showFavoritesPage();
                    else llOwnerSay("No favorites yet.");
                    return;
                }
            }
            else if (prefix == "CMCTRL")
            {
                string ctl = llList2String(p, 1);
                if (ctl == "RESUME")
                {
                    string resumeState = llList2String(p, 2);
                    if (resumeState == "RESUMED" || resumeState == "PLAYING")
                    {
                        setPlayActive(TRUE);
                    }
                    else
                    {
                        setPlayActive(FALSE);
                        llOwnerSay("No MIDI currently playing or paused.");
                    }
                    return;
                }
            }
            return;
        }
    }

    timer()
    {
        float now = llGetTime();
        integer i = llGetListLength(flashLinks) - 1;
        for (; i >= 0; --i)
        {
            if (now >= llList2Float(flashUntil, i))
            {
                integer linkNum = llList2Integer(flashLinks, i);
                setButtonColor(linkNum, COLOR_WHITE);
                flashLinks = llDeleteSubList(flashLinks, i, i);
                flashUntil = llDeleteSubList(flashUntil, i, i);
            }
        }
        updateFlashTimer();
    }
}
