params [["_marker","",[""]],["_groups",[],[[]]]];
private ["_totalCount","_reinfStrength"];

if (typeName _marker != "STRING") exitWith {format ["Error in fn_setGarrisonSize: data type mismatch, marker: ",_marker]};
if (_marker == "") exitWith {"Error in fn_setGarrisonSize: no marker set."};

_totalCount = 0;
{
	_totalCount = _totalCount + (count units _x);
} forEach _groups;

garrison setVariable [format ["%1_full", _marker],_totalCount,true];
_reinfStrength = ceil random [(_totalCount/2) - round(_totalCount/4),(_totalCount/2),(_totalCount/2) + round(_totalCount/5)];

diag_log format ["Garrison at %1 had its full strength defined as %2, with reinforcements coming in at %3", _marker,_totalCount,_reinfStrength];

[_totalCount,_reinfStrength]