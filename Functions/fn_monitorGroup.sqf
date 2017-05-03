params ["_group", ["_maxSpread", 400, [0]], ["_forceRTB", false, [true]], ["_home", [], [[]]], ["_maxDistance", 1000, [0]]];

if (_forceRTB AND {(count _home == 0)}) exitWith {diag_log format ["Error in monitorGroup: %1 was ordered to RTB without specifying a location.", _group]};

// order units to converage back onto the group leader if they strayed too far
_fn_regroup = {
	params ["_group", "_maxSpread"];
	private ["_leader", "_subordinates"];

	_leader = leader _group;
	_subordinates = (units _group) - [_leader];

	{
		if (_x distance2D _leader > _maxSpread) then {
			_x doMove (getPos _leader);
			diag_log format ["%1 has been ordered to move to %2", _x, getPos _leader];
		};
	} forEach _subordinates;
};

// order groups to return to their zones if they strayed too far
_fn_rtb = {
	params ["_group", "_home", "_maxDistance", "_fn_relax"];
	private ["_leader", "_wpInf1", "_NearestEnemy", "_TimeShot"];

	_leader = leader _group;
	if (_leader distance2D _home > _maxDistance) then {
		waitUntil {sleep 10; [_group] spawn _fn_relax; behaviour _leader != "COMBAT"};
		{_x setvariable ["VCOM_NOPATHING_Unit",true]} foreach (units _group);
		_wpInf1 = _group addWaypoint [_home, 50];
		_wpInf1 setWaypointType "MOVE";
		_wpInf1 setWaypointSpeed "FULL";
		_wpInf1 setWaypointStatements ["true", "{_x setvariable ['VCOM_NOPATHING_Unit',true]} foreach thisList"];
	};
};

// try to force units out of combat if there are no known enemies nearby
_fn_relax = {
	params ["_group"];
	private ["_NearestEnemy", "_TimeShot"];

	{
		_NearestEnemy = _x call VCOMAI_ClosestEnemy;
		if ((isNil "_NearestEnemy") OR {(_NearestEnemy isEqualTo [])}) exitwith {_x setBehaviour "SAFE"};

		_TimeShot = _Unit getVariable ["VCOM_FiredTime",0];
		if (((diag_tickTime - _TimeShot) > 120) AND {((_NearestEnemy distance2d _x) > 1000)}) then {
			_x setBehaviour "SAFE";
		};
	} forEach units _group;
};

while {({alive _x} count (units _group)) > 1} do {
	[_group, _maxSpread] call _fn_regroup;
	if (_forceRTB) then {
		[_group, _home, _maxDistance, _fn_relax] spawn _fn_rtb;
	};

	sleep 60;
};