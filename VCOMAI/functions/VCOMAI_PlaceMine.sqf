if (VCOM_MineLayChance < (random 100)) exitWith {};

private ["_endTime"];

_Unit = _this select 0;
_MineType = _this select 1;
_MagazineName = _this select 2;

_Unit removeMagazine _MagazineName;

if (_MineType isEqualTo []) exitWith {};


//systemchat format ["I %1",_Unit];
_NearestEnemy = _Unit call VCOMAI_ClosestEnemy;
if (_NearestEnemy isEqualTo [] || {isNil "_NearestEnemy"}) exitWith {};

_mine = [];

if (_NearestEnemy distance _Unit < 200) then
{
	_mine = createMine [_MineType,getposATL _Unit, [], 0];
}
else
{
	_NearRoads = _Unit nearRoads 50;
	if (count _NearRoads > 0) then
	{
		_ClosestRoad = [_NearRoads,_Unit] call VCOMAI_ClosestObject;
		_Unit doMove (getpos _ClosestRoad);
		waitUntil {!(alive _Unit) || _Unit distance _ClosestRoad < 6};
		_mine = createMine [_MineType,getposATL _ClosestRoad, [], 0];
	}
	else
	{
		_mine = createMine [_MineType,getposATL _Unit, [], 0];
	};
};

_UnitSide = (side _Unit);


if (_mine isEqualTo []) exitWith {};

[_mine,_UnitSide] spawn
{
	_Mine = _this select 0;
	_UnitSide = _this select 1;
	_endTime = diag_tickTime + 600;
	_NotSafe = true;

	diag_log format ["mine will detonate at %1", _endTime];

	while {alive _mine AND {_NotSafe} AND {(diag_tickTime < _endTime)}} do
	{
		/* _Array1 = [];
		{
			if !((side _x) isEqualTo _UnitSide) then {_Array1 pushback _x;};//todo modified
		} foreach allUnits; */
		if (_UnitSide == side_blue) then {
			_Array1 = (_Mine nearEntities [enemyCat + ["Car", "Tank"], 100]) + ((_Mine nearEntities [vehCat, 100]) select {(side _x == side_green) OR {(side _x == side_red)}});
		} else {
			_Array1 = (_Mine nearEntities [vehCat, 100]) select {_x getVariable ["BLUFORSpawn",false]} + (_Mine nearEntities [solCat, 100]);
		};

		_ClosestEnemy = [_Array1,_Mine] call VCOMAI_ClosestObject;
		if (_ClosestEnemy distance _Mine < 2.5) then {_NotSafe = false;};
		sleep 0.5;
	};
	diag_log format ["mine detonated at %1", diag_tickTime];
	_Mine setdamage 1;
};