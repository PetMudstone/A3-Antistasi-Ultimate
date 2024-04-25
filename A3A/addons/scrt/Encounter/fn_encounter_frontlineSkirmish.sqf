#include "..\defines.inc"
FIX_LINE_NUMBERS()

Info("Skirmish frontline event Init.");

private _difficult = random 10 < tierWar;
private _difficult2 = random 10 < tierWar; ///maybe add a war level check, if high -> big battle

private _player = selectRandom (call SCRT_fnc_misc_getRebelPlayers);

if (isNil "_player") exitWith {
    Error("No players found, aborting.");
    isEventInProgress = false;
    publicVariableServer "isEventInProgress";
};

private _originPosition = position _player;
Info_2("%1 will be used as center of the event at %2 position.", name _player, str _originPosition);

/* private _potentialOutposts = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {
    sidesX getVariable [_x, sideUnknown] != teamPlayer && {(getMarkerPos _x) distance2D _player < distanceSPWN*5}
}; */
/* private _frontLine = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {([_x] call A3A_fnc_isFrontline && {sidesX getVariable [_x,sideUnknown] != teamPlayer}) && {(getMarkerPos _x) distance2D _player < distanceSPWN*2}};
diag_log _frontLine;
diag_log _frontLine;
diag_log _frontLine;
diag_log _frontLine;

diag_log _frontLine; */
private _frontLine = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {([_x] call A3A_fnc_isFrontline && {sidesX getVariable [_x,sideUnknown] != teamPlayer})};
private _frontlineSitesNearPlayer = ((outposts + milbases + airportsX + resourcesX + factories + citiesX) select {(_x in _frontLine) && {((getMarkerPos _x) distance2D _player < distanceSPWN*2) && {sidesX getVariable [_x,sideUnknown] != teamPlayer}}}) call BIS_fnc_arrayShuffle;

if (_frontlineSitesNearPlayer isEqualTo []) exitWith {
    Info("No outposts in proximity, aborting Skirmish fronline Event.");
    isEventInProgress = false;
    publicVariableServer "isEventInProgress";
};

private _FrontlineOutpost = selectRandom _frontlineSitesNearPlayer;
/* private _fnc_actualFrontline = {
	params ["_markerX"];

	private _isFrontier = false;
	private _sideX = sidesX getVariable [_markerX,sideUnknown];
	//private _sideX2 = sidesX getVariable [_markerX,Invaders];
	//private _mrksideX = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {sidesX getVariable [_x,sideUnknown] == _sideX};
	private _mrksideX2 = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {sidesX getVariable [_x,sideUnknown] != _sideX};
	//private _PosmrksideX = getMarkerPos _mrksideX;
	private _PosmrksideX = getMarkerPos _markerX;
	private _PosmrksideX2 = getMarkerPos _mrksideX2;

	if (_PosmrksideX distance _PosmrksideX2 <= distanceSPWN*3) then {
		_isFrontier = true;
	};
}; */
///private _frontierX = [_FrontlineOutpost] call _fnc_actualFrontline;

private _side = Occupants;
private _side2 = Invaders;
private _faction = Faction(_side);
private _faction2 = Faction(_side2);
private _FrontlineOutpostPosition = _originPosition ;//getMarkerPos _FrontlineOutpost;

private _specOpsArray = if (_difficult) then {selectRandom (_faction get "groupSpecOpsRandom")} else {selectRandom ([_faction, "groupsTierSquads"] call SCRT_fnc_unit_flattenTier)};     ///
private _specOpsArray2 = if (_difficult2) then {selectRandom (_faction2 get "groupSpecOpsRandom")} else {selectRandom ([_faction2, "groupsTierSquads"] call SCRT_fnc_unit_flattenTier)}; ///maybe move this into fuction and roll every time?

_skirmishposition = [_FrontlineOutpostPosition, distanceSPWN0, distanceSPWN*1.1, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos; ///pos player , distance distance spwn
_skirmishposition2 = [_skirmishposition, 50, 250, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;


private _fnc_spawngroups = {
	params ["_amount","_amount2", "_vehiclesAmount" , "_vehiclesAmount2" , "_difficult" , "_difficult2"];
	for "_i" from 1 to _amount do {
		_skirmishpositionActuall = [_skirmishposition, 40, 200, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_InfGroup = [_skirmishpositionActuall, _side, _specOpsArray] call A3A_fnc_spawnGroup;
		{[_x] call A3A_fnc_NATOinit} forEach units _InfGroup;
		_InfGroup setBehaviourStrong "AWARE";
		private _wp = _InfGroup addWaypoint [_skirmishposition, 50];
		_wp setWaypointSpeed "NORMAL";
		_wp setWaypointType "SAD";
		_InfGroups pushBack _InfGroup;

		private _vehicles = if (_difficult) then {selectRandom ((_faction get "vehiclesAirborne") + (_faction get "vehiclesLightTanks") + (_faction get "vehiclesTanks") + (_faction get "vehiclesAPCs") + (_faction get "vehiclesIFVs"))
					} else {selectRandom
					((_faction get "vehiclesLightUnarmed") + (_faction get "vehiclesLightArmed") + (_faction get "vehiclesAirborne") + (_faction get "vehiclesLightTanks") + (_faction get "vehiclesMilitiaAPCs") + 
					(_faction get "vehiclesMilitiaLightArmed") + (_faction get "vehiclesMilitiaCars"))
		};///add a check for a crew or vehicle type, if met order getout because weak vehicle or unarmed.
		diag_log _vehicles;
		_skirmishpositionActuall = [_skirmishposition, 50, 250, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_vehicledata = [_skirmishpositionActuall, 0, _vehicles, _side] call A3A_fnc_spawnVehicle;
		_vehicle = _vehicledata select 0;
		_vehiclegroup = _vehicledata select 2;
		[_vehicle, Occupants] call A3A_fnc_AIVEHinit;
		_vehiclegroup setBehaviourStrong "AWARE";
		/* private _wpveh = _vehiclegroup addWaypoint [_skirmishposition, 50];
		_wpveh setWaypointSpeed "NORMAL";
		_wpveh setWaypointType "SAD"; */
		//{_x assignAsCargo _vehicle} forEach units _InfGroup;
		//units _vehiclegroup join _InfGroup;
		if (_difficult) then {
			_UAVtype = selectRandom (_faction get "uavsPortable");
			_uav = createVehicle [_UAVtype, _skirmishpositionActuall, [], 0, "FLY"];
			[_side, _uav] call A3A_fnc_createVehicleCrew;
			_vehiclesArray pushBack _uav;
			_groupUAV = group (crew _uav select 1);
			{[_x] joinSilent _InfGroup} forEach units _groupUAV;
		};
		[_InfGroup, "Patrol_Attack", 0, 300, 1000, true, _skirmishposition, true] call A3A_fnc_patrolLoop;
		[_vehiclegroup, "Patrol_Area", 0, 300, 1000, true, _skirmishposition, false] call A3A_fnc_patrolLoop;
		_vehiclesArray pushBack _vehicle;
	};
	for "_i" from 1 to _amount2 do {
		_skirmishpositionActuall2 = [_skirmishposition2, 100, 250, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_InfGroup2 = [_skirmishpositionActuall2, _side2, _specOpsArray2] call A3A_fnc_spawnGroup;
		{[_x] call A3A_fnc_NATOinit} forEach units _InfGroup2;
		_InfGroup2 setBehaviourStrong "AWARE";
		private _wp = _InfGroup2  addWaypoint [_skirmishposition, 50];
		_wp setWaypointSpeed "NORMAL";
		_wp setWaypointType "SAD";
		_InfGroups2 pushBack _InfGroup2;

		private _vehicles2 = if (_difficult2) then {selectRandom ((_faction2 get "vehiclesAirborne") + (_faction2 get "vehiclesLightTanks") + (_faction2 get "vehiclesTanks") + (_faction2 get "vehiclesAPCs") + (_faction2 get "vehiclesIFVs"))
					} else {selectRandom
					((_faction2 get "vehiclesLightUnarmed") + (_faction2 get "vehiclesLightArmed") + (_faction2 get "vehiclesAirborne") + (_faction2 get "vehiclesLightTanks") + (_faction2 get "vehiclesMilitiaAPCs") + 
					(_faction2 get "vehiclesMilitiaLightArmed") + (_faction2 get "vehiclesMilitiaCars"))
		};
		diag_log _vehicles2;
		_skirmishpositionActuall2 = [_skirmishposition2, 150, 350, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_vehicledata2 = [_skirmishpositionActuall2, 0,_vehicles2, _side2] call A3A_fnc_spawnVehicle;
		_vehicle2 = _vehicledata2 select 0;
		_vehiclegroup2 = _vehicledata2 select 2;
		[_vehicle2, Invaders] call A3A_fnc_AIVEHinit;
		_vehiclegroup2 setBehaviourStrong "AWARE";
		/* private _wpveh2 = _vehiclegroup2 addWaypoint [_skirmishposition, 50];
		_wpveh2 setWaypointSpeed "NORMAL";
		_wpveh2 setWaypointType "SAD"; */
		//{_x assignAsCargo _vehicle2} forEach units _InfGroup2;
		//units _vehiclegroup2 join _InfGroup2;
		if (_difficult2) then {
			_UAV2type = selectRandom (_faction2 get "uavsPortable");
			_uav2 = createVehicle [_UAV2type, _skirmishpositionActuall2, [], 0, "FLY"];
			[_side2, _uav2] call A3A_fnc_createVehicleCrew;
			_vehiclesArray2 pushBack _uav2;
			_groupUAV2 = group (crew _uav2 select 1);
			{[_x] joinSilent _InfGroup2} forEach units _groupUAV2;
		};
		[_InfGroup2, "Patrol_Attack", 0, 300, 1000, true, _skirmishposition, true] call A3A_fnc_patrolLoop;
		[_vehiclegroup2, "Patrol_Area", 0, 300, 1000, true, _skirmishposition, true] call A3A_fnc_patrolLoop;
		_vehiclesArray2 pushBack _vehicle2;
	};
	/* for "_i" from 1 to _vehiclesAmount do {
		private _vehicles = if (_difficult) then {selectRandom ((_faction get "vehiclesAirborne") + (_faction get "vehiclesLightTanks") + (_faction get "vehiclesTanks") + (_faction get "vehiclesAPCs") + (_faction get "vehiclesIFVs"))
					} else {selectRandom
					((_faction get "vehiclesLightUnarmed") + (_faction get "vehiclesLightArmed") + (_faction get "vehiclesAirborne") + (_faction get "vehiclesLightTanks") + (_faction get "vehiclesMilitiaAPCs") + 
					(_faction get "vehiclesMilitiaLightArmed") + (_faction get "vehiclesMilitiaCars"))
		};///add a check for a crew or vehicle type, if met order getout because weak vehicle or unarmed.
		diag_log _vehicles;
		_skirmishpositionActuall = [_skirmishposition, 30, 200, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_vehicledata = [_skirmishpositionActuall, 0, _vehicles, _side] call A3A_fnc_spawnVehicle;
		_vehicle = _vehicledata select 0;
		_vehiclegroup = _vehicledata select 2;
		[_vehicle, Occupants] call A3A_fnc_AIVEHinit;
		_vehiclegroup setBehaviourStrong "AWARE";
		private _wp = _vehiclegroup addWaypoint [_skirmishposition, 0];
		_wp setWaypointSpeed "NORMAL";
		_wp setWaypointType "SAD";
		{[_x] assignAsCargo _vehicle} forEach units _InfGroup;
		units _vehiclegroup2 join _InfGroup;
		_vehiclesArray pushBack _vehicle;
	};
	for "_i" from 1 to _vehiclesAmount2 do {
		private _vehicles2 = if (_difficult2) then {selectRandom ((_faction2 get "vehiclesAirborne") + (_faction2 get "vehiclesLightTanks") + (_faction2 get "vehiclesTanks") + (_faction2 get "vehiclesAPCs") + (_faction2 get "vehiclesIFVs"))
					} else {selectRandom
					((_faction2 get "vehiclesLightUnarmed") + (_faction2 get "vehiclesLightArmed") + (_faction2 get "vehiclesAirborne") + (_faction2 get "vehiclesLightTanks") + (_faction2 get "vehiclesMilitiaAPCs") + 
					(_faction2 get "vehiclesMilitiaLightArmed") + (_faction2 get "vehiclesMilitiaCars"))
		};
		diag_log _vehicles2;
		_skirmishpositionActuall2 = [_skirmishposition2, 125, 350, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_vehicledata2 = [_skirmishpositionActuall2, 0,_vehicles2, _side2] call A3A_fnc_spawnVehicle;
		_vehicle2 = _vehicledata2 select 0;
		_vehiclegroup2 = _vehicledata2 select 2;
		[_vehicle2, Invaders] call A3A_fnc_AIVEHinit;
		_vehiclegroup2 setBehaviourStrong "AWARE";
		private _wp = _vehiclegroup2 addWaypoint [_skirmishposition, 0];
		_wp setWaypointSpeed "NORMAL";
		_wp setWaypointType "SAD";
		{[_x] assignAsCargo _vehicle2} forEach units _InfGroup2;
		units _vehiclegroup2 join _InfGroup2;
		_vehiclesArray2 pushBack _vehicle2;
	}; */
};
private _amount = round random 3;
if (_amount == 0) then {
	_amount = 1;
};
private _amount2 = round random 3;
if (_amount2 == 0) then {
	_amount2 = 1;
};
private _vehiclesAmount = round random 3;
private _vehiclesAmount2 = round random 3;
private _InfGroups = [];
private _InfGroups2 = [];
private _vehiclesArray = [];
private _vehiclesArray2 = [];

[_amount, _amount2, _vehiclesAmount , _vehiclesAmount2 ,_difficult ,_difficult2] call _fnc_spawngroups;
///dissable AI and wait until players are nearby? or just wait until players are nearby and then spawn units

private _timeOut = time + 3600;
waitUntil {time > _timeOut && (call SCRT_fnc_misc_getRebelPlayers) inAreaArray [_skirmishposition, distanceSPWN1, distanceSPWN1] isEqualTo []};
/* _player distance2D _skirmishposition > 2000   */
///If someone survived -> move to base from the check above?
///some sort of check needed to delete groups and vehicles smart way
{[_x] spawn A3A_fnc_vehDespawner} forEach _vehicles;
{[_x] spawn A3A_fnc_groupDespawner} forEach _InfGroups;
{[_x] spawn A3A_fnc_groupDespawner} forEach _InfGroups2;

isEventInProgress = false;
publicVariableServer "isEventInProgress";

Info("Frontline skirmish clean up event complete.");