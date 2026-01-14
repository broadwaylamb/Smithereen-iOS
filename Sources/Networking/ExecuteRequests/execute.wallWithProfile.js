var owner_id = Args.owner_id;
var wall = API.wall.get({
	owner_id: owner_id,
	offset: Args.offset,
	count: Args.count,
	filter: Args.filter,
	fields: Args.fields,
	extended: true
});
var owner;
var profilesArray;
if (owner_id < 0) {
	owner_id = -owner_id;
	owner = API.groups.getById({group_ids: owner_id, fields: Args.fields})[0];
	profilesArray = wall.groups;
} else {
	owner = API.users.get({user_ids: owner_id, fields: Args.fields})[0];
	profilesArray = wall.profiles;
}
var replaced = false;
for (var i = 0; i < profilesArray.length; i = i + 1) {
	if (profilesArray[i].id == owner_id) {
		profilesArray[i] = owner;
		replaced = true;
	}
}
if (!replaced) {
	profilesArray.push(owner);
}
return wall;
