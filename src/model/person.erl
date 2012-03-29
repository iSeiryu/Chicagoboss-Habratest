-module(person, [Id, Name, PwdHash, Notes]).
-define(SECRET_STRING, "Don't tell anyone!").
-compile(export_all).

session_identifier()->
    mochihex:to_hex(erlang:md5(?SECRET_STRING ++ Id)).

check_password(Password) ->
    Salt = mochihex:to_hex(erlang:md5(Name)),
    user_lib:hash_password(Password, Salt) =:= binary_to_list(PwdHash).

login_cookies()->
    [ mochiweb_cookies:cookie("user_id", Id, [{path, "/"}]),
        mochiweb_cookies:cookie("session_id", session_identifier(), [{path, "/"}]) ].

validation_tests() ->
  [{fun() -> length(Name) > 0 end,
		"Please enter a name"},
	{fun() -> length(PwdHash) > 0 end,
		"Please enter a password"},
	{fun() -> boss_db:find(person, [{name, Name}], 1) == [] end,
		"Please choose a different name"}].
