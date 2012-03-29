-module(addressbook_user_controller, [Req, SessionID]).
-compile([export_all]).

%Chicago Boss checks to see if the controller has an before_ function. If so, it passes the action name to the before_ function and checks the return value.
before_(_) ->
    user_lib:check_user(Req).

showall('GET', [], Person)->
	{ok, [{persons, boss_db:find(person, [])},{ip, Req:peer_ip()},{count, boss_db:count(person)},{person,Person}]}.

login('GET', [], Person)->
	 case Person==undefined of
		false ->
			{redirect, "/user/showall/"};
		true ->
    		{ok, [{redirect, Req:header(referer)},{ip, Req:peer_ip()},{person,Person}]}
	 end;
login('POST', [], Person) ->

    Name = Req:post_param("name"),

    case boss_db:find(person, [{name, Name}], 1) of
        [User] ->
            case User:check_password(Req:post_param("password")) of
                true ->
                    {redirect, proplists:get_value("redirect",
                        Req:post_params(), "/"), User:login_cookies()};

                false ->
                    {ok, [{error, "Bad name/password combination"},{ip, Req:peer_ip()}]}
            end;

        [] ->
            {ok, [{error, "No Person named " ++ Name},{ip, Req:peer_ip()}]}
    end.

logout('GET', []) ->
    {redirect, "/",
        [ mochiweb_cookies:cookie("user_id", "", [{path, "/"}]),
            mochiweb_cookies:cookie("session_id", "", [{path, "/"}]) ]}.

register('GET', [], Person) ->
	 case Person==undefined of
		false ->
			{redirect, "/user/showall/"};
		true ->
    		{ok, [{ip, Req:peer_ip()},{person,Person}]}
	 end;
register('POST', [], Person) ->
    NewPerson = person:new(id, Req:post_param("name"), user_lib:hash_for(Req:post_param("name"), Req:post_param("password")), Req:post_param("notes")),
    case NewPerson:save() of
        {ok, SavedPerson} ->
            {redirect, "/user/showall/"};
        {error, Errors} ->
           {ok, [{errors, Errors}, {ip, Req:peer_ip()}]}
    end.
