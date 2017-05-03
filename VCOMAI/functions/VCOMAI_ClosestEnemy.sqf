private ["_Unit", "_ReturnedEnemy"];
//Created on ???
// Modified on : 8/19/14 - 8/3/15

//todo modified
_Unit = _this;

_ReturnedEnemy = _Unit findNearestEnemy _Unit;
if (isNull _ReturnedEnemy) exitWith {[0,0,0]};

_ReturnedEnemy