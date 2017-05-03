params [["_marker","",[""]],["_unitCount",1,[1]]];
private ["_reinfStrength"];

if (typeName _marker != "STRING") exitWith {format ["Error in fn_setGarrisonSize: data type mismatch, marker: ",_marker]};
if (_marker == "") exitWith {"Error in fn_setGarrisonSize: no marker set."};

garrison setVariable [format ["%1_full", _marker],_unitCount,true];
_reinfStrength = ceil random [(_unitCount/2) - round(_unitCount/4),(_unitCount/2),(_unitCount/2) + round(_unitCount/5)];

diag_log format ["Garrison at %1 had its full strength defined as %2, with reinforcements coming in at %3", _marker,_unitCount,_reinfStrength];

[_unitCount,_reinfStrength]