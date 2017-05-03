params ["_heli"];

doStop (driver _heli);
_heli flyinheight 50;

waitUntil {sleep 1; ((abs (speed _heli)) < 5) OR {!alive _heli}};

if (alive _heli) then {
	[group ((assignedCargo _heli) select 0)] spawn SHK_Fastrope_fnc_AIs;
};