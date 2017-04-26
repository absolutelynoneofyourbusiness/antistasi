if (!isServer and hasInterface) exitWith {};

params ["_target"];
private ["_posTarget", "_posBase", "_allSoldiers", "_allGroups", "_allVehicles", "_endTime", "_targetName", "_baseName", "_numSoldiers","_base","_tempData"];

[[],[],[]] params ["_allVehicles","_allSoldiers","_allGroups"];

#define DURATION 30
#define DELAY 1

if ({toLower _x find "int_" > 0} count misiones > 3) exitWith {diag_log "Info: replenishment task killed, maximum number of parallel tasks reached."};
if ((format ["INT_%1",_target]) in misiones) exitWith {diag_log format ["Info: replenishment task killed, %1 already receiving replenishments.", _target]};

_base = [_target,false,true] call AS_fnc_findBaseForCA;
if (_base == "") exitWith {diag_log format ["Info: replenishment task killed, no base available.", _target]};

diag_log format ["REP triggered: %1", _target];

_tskTitle = localize "STR_TSK_INTRREPL";
_tskDesc = localize "STR_TSKDESC_INTRREPL";

_posBase = getMarkerPos _base;
_posTarget = getMarkerPos _target;

_endTime = [date select 0, date select 1, date select 2, date select 3, (date select 4) + DURATION];
_endTime = dateToNumber _endTime;

_targetName = [_target] call AS_fnc_localizar;
_baseName = [_base] call AS_fnc_localizar;
//[_base, 5] spawn AS_fnc_addTimeForIdle;

_tsk = [format ["INT_%1",_target],[side_blue,civilian],[format [_tskDesc, A3_Str_INDEP, _targetName, _baseName],format [_tskTitle, A3_Str_INDEP],_target],_posTarget,"CREATED",5,true,true,"Destroy"] call BIS_fnc_setTask;
misiones pushBack _tsk; publicVariable "misiones";

sleep (DELAY * 60);

/*
	MRAP:
	_tempData = [selectRandom vehLead,[[sol_SL], side_green] call AS_fnc_pickGroup,1,_posBase,_target] call AS_fnc_groundTransport;

	Truck:
	_tempData = [selectRandom vehTrucks,[infSquad, side_green] call AS_fnc_pickGroup,2,_posBase,_target] call AS_fnc_groundTransport;

	APC:
	_tempData = [selectRandom vehAPC,[infSquad, side_green] call AS_fnc_pickGroup,1,_posBase,_target] call AS_fnc_groundTransport;

	IFV:
	_tempData = [selectRandom vehIFV,[infTeam, side_green] call AS_fnc_pickGroup,1,_posBase,_target] call AS_fnc_groundTransport;
*/

call {
	if (_target in (bases+aeropuertos)) exitWith {
		_tempData = [selectRandom vehAPC,[infSquad, side_green] call AS_fnc_pickGroup,1,_posBase,_target] call AS_fnc_groundTransport;
		_allVehicles = _allVehicles + (_tempData select 0);
		_allGroups = _allGroups + (_tempData select 1);
		sleep 5;
		_tempData = [selectRandom vehTrucks,[infSquad, side_green] call AS_fnc_pickGroup,2,_posBase,_target] call AS_fnc_groundTransport;
	};

	if (_target in (puestos+puestosAA)) exitWith {
		_tempData = [selectRandom vehLead,[[sol_SL], side_green] call AS_fnc_pickGroup,1,_posBase,_target] call AS_fnc_groundTransport;
		_allVehicles = _allVehicles + (_tempData select 0);
		_allGroups = _allGroups + (_tempData select 1);
		sleep 5;
		_tempData = [selectRandom vehTrucks,[infSquad, side_green] call AS_fnc_pickGroup,2,_posBase,_target] call AS_fnc_groundTransport;
	};

	if (_target in (colinas-colinasAA+controles)) exitWith {
		_tempData = [selectRandom vehLead,[[sol_SL], side_green] call AS_fnc_pickGroup,1,_posBase,_target] call AS_fnc_groundTransport;
	};

	if (_target in (recursos+fabricas+power)) exitWith {
		_tempData = [selectRandom vehTrucks,[infSquad, side_green] call AS_fnc_pickGroup,2,_posBase,_target] call AS_fnc_groundTransport;
	};

	_tempData = [selectRandom vehTrucks,[infSquad, side_green] call AS_fnc_pickGroup,2,_posBase,_target] call AS_fnc_groundTransport;
};

_allVehicles = _allVehicles + (_tempData select 0);
_allGroups = _allGroups + (_tempData select 1);

{
	_group = _x;
	_group allowFleeing 0;
	{
		[_x] spawn genInit;
		_allSoldiers pushBack _x;
	} forEach units _group;
} forEach _allGroups;

{
	[_x] spawn genVEHinit;
	_x limitSpeed 50;
} forEach _allVehicles;

_numSoldiers = count _allSoldiers;

waitUntil {sleep 1; (dateToNumber date > _endTime) or ({_x distance _posTarget < 150} count _allSoldiers > round(_numSoldiers/3)) or (3*({(alive _x) and !(captive _x)} count _allSoldiers) < _numSoldiers)};

if ({_x distance _posTarget < 150} count _allSoldiers > round(_numSoldiers/3)) then {
	_tsk = [format ["INT_%1",_target],[side_blue,civilian],[format [_tskDesc, A3_Str_INDEP, _targetName, _baseName],format [_tskTitle, A3_Str_INDEP],_target],_posTarget,"FAILED",5,true,true,"Destroy"] call BIS_fnc_setTask;
	[-10, Slowhand] call playerScoreAdd;
	garrison setVariable [format ["%1_reduced", _target],false,true];
} else {
	_tsk = [format ["INT_%1",_target],[side_blue,civilian],[format [_tskDesc, A3_Str_INDEP, _targetName, _baseName],format [_tskTitle, A3_Str_INDEP],_target],_posTarget,"SUCCEEDED",5,true,true,"Destroy"] call BIS_fnc_setTask;
	[10, Slowhand] call playerScoreAdd;
};

[5, _tsk] spawn borrarTask;

[_allGroups, _allSoldiers, _allVehicles] spawn AS_fnc_despawnUnits;