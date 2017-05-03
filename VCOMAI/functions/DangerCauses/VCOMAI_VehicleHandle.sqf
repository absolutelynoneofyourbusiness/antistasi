/*_AssignedCargo = assignedCargo (vehicle _this);

if (_this in _AssignedCargo) then
{
	[_this] orderGetIn false;
	_this leaveVehicle (vehicle _this);
	unassignVehicle _this;
	commandGetOut _this;
	doGetOut _this;
	_this action ["eject", (vehicle _this)];
	(vehicle _this) land "GET OUT";
	(vehicle _this) land "GET OUT";
};*/