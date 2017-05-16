params ["_vehGroup", "_origin", "_dest", "_radius", "_duration"];

_wp101 = _vehGroup addWaypoint [_dest, 50];
_wp101 setWaypointType "LOITER";
_wp101 setWaypointLoiterType "CIRCLE";
_wp101 setWaypointLoiterRadius _radius;
_wp101 setWaypointSpeed "LIMITED";

if ((vehicle (leader _vehGroup)) isKindOf "UAV") then {(vehicle (leader _vehGroup)) flyInHeight 300};

sleep _duration;
[_vehGroup, _origin] spawn AS_fnc_QRF_RTB;