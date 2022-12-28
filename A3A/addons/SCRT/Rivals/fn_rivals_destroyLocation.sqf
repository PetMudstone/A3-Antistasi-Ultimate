/*
Maintainer: Socrates
    Destroy locations so it won't be used as base of operations by Rivals.

Return Value:
    <POSITION> Some position if position search succeded, empty array if not. 

Scope: Server
Environment: Any
Public: Yes
Dependencies:
    <NUMBER> baseRivalsDecay
	<HASHMAP> rivalsLocationsMap

Example:
[_marker] call SCRT_fnc_rivals_destroyLocation;
*/
#include "..\defines.inc"
FIX_LINE_NUMBERS()


params ["_location", "_source"];

private _radiusOfOperations = (sqrt 2 / 2 * worldSize) / 8;
private _locations = ["UNKNOWN"] call SCRT_fnc_rivals_getLocations;

if (isNil "_locations") exitWith {
    Error("Empty locations");
};

private _closeLocations = _locations select { _x distance2D (getMarkerPos _location) <= _radiusOfOperations };
(_closeLocations + [_location]) apply {
    rivalsLocationsMap deleteAt _x;
};
publicVariable "rivalsLocationsMap";

if (rivalsLocationsMap isEqualTo createHashMap) exitWith {
    [] remoteExecCall ["SCRT_fnc_rivals_defeat", 2];
};

[(round (random [50, 60, 75])), (100/baseRivalsDecay)] call SCRT_fnc_rivals_reduceActivity;

private _name = [_location] call A3A_fnc_localizar;
private _text = if (_source isEqualTo "CELL") then {
    format [
        localize "STR_rivals_destroyed_city", 
        A3A_faction_riv get "name",
        _location
    ];
} else {
    format [
        localize "STR_rivals_destroyed_hideout", 
        A3A_faction_riv get "name",
        _location
    ];
};
[petros, "announce", _text] remoteExec ["A3A_fnc_commsMP", 0];