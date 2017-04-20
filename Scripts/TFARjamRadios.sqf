/*
	Created by: rebel12340
*/

if (!hasInterface) exitwith {};

params [["_jammerObjects",[objNull],[]],["_radius",1000,[0]],["_strength",100,[0]],["_debug",false,[false]]];
private ["_jammer","_closestDist","_dist","_distPercent","_interference"];

//compare distances between jammers and player to find nearest jammer and set it as _jammer
_jammerDist = {
	_jammer = objNull;
	_closestDist = 1000000;
	{
		if (_x distance player < _closestdist) then {
			_jammer = _x;
			_closestDist = _x distance player;
		};
	} foreach _jammerObjects;
	_jammer;
};
_jammer = call _jammerDist;

// While the Jamming Vehicle is not destroyed, loop every 5 seconds
while {alive _jammer AND (jamTest)} do {
    // Set variables
    _dist = player distance _jammer;
    _distPercent = _dist / _radius;
    _interference = 1;

    if (_dist < _radius) then {
		_interference = _strength - (_distPercent * _strength) + 1;
    };
    // Set the TF receiving and transmitting distance multipliers
    player setVariable ["tf_receivingDistanceMultiplicator", _interference];
	player setVariable ["tf_transmittingDistanceMultiplicator", _interference];

    // Debug chat and marker.
	if (_debug) then {
		deletemarker "CIS_DebugMarker";
		deletemarker "CIS_DebugMarker2";
		//Area marker
		_debugMarker = createmarker ["CIS_DebugMarker", position _jammer];
		_debugMarker setMarkerShape "ELLIPSE";
		_debugMarker setMarkerSize [_radius, _radius];

		//Position Marker
		_debugMarker2 = createmarker ["CIS_DebugMarker2", position _jammer];
		_debugMarker2 setMarkerShape "ICON";
		_debugMarker2 setMarkerType "mil_dot";
		_debugMarker2 setMarkerText format ["%1", _jammer];

		systemChat format ["Distance: %1, Percent: %2, Interference: %3", _dist,  100 * _distPercent, _interference];
		systemChat format ["Active Jammer: %1, Jammers: %2",_jammer, _jammerObjects];
		//copyToClipboard (str(Format ["Distance: %1, Percent: %2, Interference: %3", _dist,  100 * _distPercent, _interference]));
	};
    // Sleep 5 seconds before running again
    sleep 5.0;

	//Only run this if there are multiple jammers.
	if (count _jammerObjects > 1) then {
		//Check if all of the jammers are still alive. If not, remove it from _jammerObjects.
		{
			if (!alive _x AND count _jammerObjects > 1) then {_jammerObjects = _jammerObjects - [_x]};
		} foreach _jammerObjects;

		//Check for closest jammer
		_jammer = call _jammerDist;
	};
};

//Set TFR settings back to normal before exiting the script
player setVariable ["tf_receivingDistanceMultiplicator", 1];
player setVariable ["tf_transmittingDistanceMultiplicator", 1];