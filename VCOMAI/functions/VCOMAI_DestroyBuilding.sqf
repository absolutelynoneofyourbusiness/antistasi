private ["_Unit", "_UnitGroup", "_Point", "_PreviousPosition", "_vehicle", "_Offset", "_ToWorld1", "_ToWorld2", "_PointHeight", "_PointHeightC", "_LookVar", "_nBuilding", "_Building", "_SatchelOfUse", "_Truth", "_PrimaryWeapon", "_PrimaryWeaponItems", "_SecondaryWeapon", "_SecondaryWeaponItems", "_HandgunWeapon", "_HandgunWeaponItems"];
//Script used to make AI attach explosives to buildings and bring them down if players garrison them.
_Unit = _this;

//_UnitGroup = group _Unit;
//[_Unit] joinSilent grpNull;
//_Point = _Unit getVariable "VCOM_CLOSESTENEMY";

//systemchat format ["D %1",_Unit];
_Point = _Unit call VCOMAI_ClosestEnemy;
if (_Point isEqualTo [] || {isNil "_Point"}) exitWith {};

_PreviousPosition = (getPosATL _Unit);
if (isNil "_Point") exitWith {};
//Hint format ["_Point %1",_Point];
sleep 2;
if ((_Unit distance _Point) < 200) then
{


_vehicle = vehicle _Point;

if (_Point isEqualTo _vehicle) then {


_nBuilding = nearestBuilding _Point;
if ((_nBuilding distance _Point) > 20) exitWith {};

sleep 2;
doStop _Unit; _Unit doMove (getPos _nBuilding);
[_Unit,_nBuilding,_PreviousPosition] spawn {
_Unit = _this select 0;
_Building = _this select 1;
_PreviousPosition = _this select 2;
//_UnitGroup = _this select 3;
_SatchelOfUse = _Unit getVariable "VCOM_SATCHELBOMB";
//Hint format ["_SatchelOfUse %1",_SatchelOfUse];

if (VCOM_AIDEBUG isEqualTo 1) then
{
	[_Unit,"Blowing up a building! >:D!!!!",30,20000] remoteExec ["3DText",0];
};


_Truth = true;
while {_Truth} do {
	if ((_Unit distance _Building) <= 10) then {_Truth = false;};
	sleep 0.25;
};

_Bomb = _Unit getVariable "VCOM_SATCHELBOMB";
_RemoveMag = _Unit getVariable "Vcom_SatchelObjectMagazine";
_Unit removeMagazine _RemoveMag;
_mine = createMine [_Bomb,getposATL _unit, [], 0];

_PlantPosition = (getpos _Unit);

_NotSafe = true;
_Array1 = [];
_UnitSide = (side _Unit);
doStop _Unit;
_Unit doMove _PreviousPosition;
// {
	// if (alive _x && (side _x) isEqualTo _UnitSide) then {_Array1 pushback _x;};//todo modified
// } foreach allUnits;
_Array1 = ((getPosATL _Unit) nearEntities [[enemyCat, solCat] select (side _unit == side_blue), 100]);
while {_NotSafe} do
{
	_ClosestFriendly = [_Array1,_PlantPosition] call VCOMAI_ClosestObject;
	if (_ClosestFriendly distance _PlantPosition > 15) then {_NotSafe = false;};
	sleep 5;
};
//[_Unit] joinSilent _UnitGroup;
//Hint "TOUCH OFF!";
//_Unit action ["TOUCHOFF", _Unit];
_mine setdamage 1;
//_Unit enableAI "TARGET";
//_Unit enableAI "AUTOTARGET";
};




//};
};
};