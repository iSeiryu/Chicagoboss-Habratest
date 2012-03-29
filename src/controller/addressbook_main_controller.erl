-module(addressbook_main_controller, [Req, SessionID]).
-compile([export_all]).

%Chicago Boss checks to see if the controller has an before_ function. If so, it passes the action name to the before_ function and checks the return value.
before_(_) ->
    user_lib:check_user(Req).

index('GET', [], Person)->Addresses = boss_db:find(address, []),
	{ok, [{addresses, Addresses},{ip, Req:peer_ip()},{count, boss_db:count(address)},{person,Person}]}.

create('GET', [], Person)->{ok, [{ip, Req:peer_ip()},{person,Person}]};
create('POST', [], Person)->
	Firstname = Req:post_param("firstname"), 
	Lastname = Req:post_param("lastname"), 
	Address1 = Req:post_param("address1"), 
	Address2 = Req:post_param("address2"), 
	City = Req:post_param("city"), 
	State = Req:post_param("state"), 
	Country = Req:post_param("country"), 
	Active = Req:post_param("active"), 
	CreationTime = erlang:localtime(), 
	ModificationTime = erlang:localtime(),
	NewAddress = address:new(id, Firstname, Lastname, Address1, Address2, City, State, Country, Active, CreationTime, ModificationTime),
	case NewAddress:save() of
	{ok, SavedAddress}->
		{redirect, [{action, "index"}]};
	{error, Reason}->
		Reason
	end.

show('GET', [Id], Person)->
	Address = boss_db:find(Id),
		{ok, [{address, Address},{ip, Req:peer_ip()},{person,Person}]}.

edit('GET', [Id], Person)->
	Address = boss_db:find(Id),
		{ok, [{address, Address},{ip, Req:peer_ip()},{person,Person}]};
edit('POST', [Id], Person)->
	Address = boss_db:find(Id),
	NewAddress = Address:set([{firstname, Req:post_param("firstname")}, {lastname, Req:post_param("lastname")}, {address1, Req:post_param("address1")}, {address2, Req:post_param("address2")}, {city, Req:post_param("city")}, {state, Req:post_param("state")}, {country, Req:post_param("country")}, {active, Req:post_param("active")}, {modification_time, erlang:now()}]),
	case NewAddress:save() of
	{ok, SavedAddress}->
		{redirect, [{action, "index"}]};
	{error, Reason}->
		Reason
	end.

delete('GET', [Id])->
	boss_db:delete(Id),
		{redirect, [{action, "index"}]}.

oops('GET', [])->{redirect, [{action, "index"}]}.
