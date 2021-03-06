// ---------------------------------
//	Initialise Dynamic Urban Patrol
// ---------------------------------

private["_cnps","_towns","_previousTowns","_fnc_getRandomTown","_fnc_createTriggers"];

// Get an array of town locations in a 20000 radius from the centre of the map
_cnps = getArray (configFile >> "CfgWorlds" >> worldName >> "centerPosition");
_towns = nearestLocations [_cnps, ["nameVillage","nameCity","NameCityCapital"], 20000];

// Initialise previous town array
// This is used to prevent multiple urban patrols in the same location
_previousTowns = [];

_fnc_getRandomTown = {
	private["_town"];

	// Select a random town from array
	_town = _towns call BIS_fnc_selectRandom;
	while {(text _town == "") || (text _town in _previousTowns)} do {
		_town = _towns call BIS_fnc_selectRandom;
	};	
		
	// Add current town name to previous town array (set method is fastest)
	_previousTowns set [count _previousTowns,text _town];
	_town
};

_fnc_createTriggers = {
	private["_triggerIndex","_town","_townName","_pos","_trigName","_trig_cond","_trig_act_stmnt","_trig_deact_stmnt"];
	
	_triggerIndex = _this select 0;
	
	_town = call _fnc_getRandomTown; // Get random town
	_townName = text _town; // Get town name
	_pos = position _town; // Get position of town
	
	// Create trigger to spawn patrol
	_trigName = format ["upsTrig%1", _triggerIndex];
	_this = createTrigger ["EmptyDetector", _pos]; 
	_this setTriggerArea [500, 500, 0, false];
	_this setTriggerActivation ["WEST", "present", false];
	
	// Assign trigger conditions
	_trig_cond = "{(isPlayer _x) && ((vehicle _x) isKindOf ""Man"")} count thisList > 0"; // Trigger if any player is in range
	_trig_act_stmnt = format ["[%1, %2] execVM ""\z\addons\dayz_server\FEAR\dynamic_ups\spawn_urban_patrol.sqf""", _pos, _triggerIndex];
	_trig_deact_stmnt = format ["deleteVehicle %1", _trigName]; // Delete trigger once activated
	
	_this setTriggerStatements [_trig_cond, _trig_act_stmnt, _trig_deact_stmnt];
};

if (isServer) then {
	private["_i","_numberOfTriggers"];

	_numberOfTriggers = 7; // total triggers to create on map
	
	for "_i" from 0 to _numberOfTriggers do {
		[_i] call _fnc_createTriggers; // Use loop index to number trigger names
		sleep 0.125;
	};

	diag_log format ["[Dynamic UPS]: Urban patrol triggers created at: %1", _previousTowns];
};