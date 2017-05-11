params [
	"_origin",
	"_target",
	["_minDistance", 50, [0]],
	["_maxDistance", 400, [0]],
	["_roads", [], [[]], 0]
];

private ["_radius", "_road", "_distance", "_max"];

_maxDistance = _maxDistance max (_minDistance + 50);

_radius = +_minDistance;
while {true} do {
	_roads = _target nearRoads _radius;
	if (count _roads == 0) then {_radius = _radius + 50};
	if (count _roads > 0) exitWith {};
	if (_radius > _maxDistance) exitWith {};
};

if (count _roads == 0) exitWith {diag_log format ["No road found between %3m and %4m from %2 for troops coming from %1", _origin, _target, _minDistance, _maxDistance]};

_road = _roads select 0;
_max = -log 0;
{
	_distance = _x distanceSqr _origin;
	if (_distance < _max) then {_max = _distance; _road = _x};
} count _roads;

position _road