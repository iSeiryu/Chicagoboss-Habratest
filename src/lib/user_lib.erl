-module(user_lib).
-compile(export_all).

%User's global functions that you can use anywhere just call user_lib:[func_name]
hash_password(Password, Salt) ->
	case length(Password) > 0 of
		true ->
			mochihex:to_hex(erlang:md5(Salt ++ Password));
		false ->
			""
	end.

hash_for(Name, Password) ->
	Salt = mochihex:to_hex(erlang:md5(Name)),
	hash_password(Password, Salt).

require_login(Req) ->
    case Req:cookie("user_id") of
        undefined -> {redirect, "/user/login"};
        Id ->
            case boss_db:find(Id) of
                undefined -> {redirect, "/user/login"};
                Person ->
                    case Person:session_identifier() =:= Req:cookie("session_id") of
                        false -> {redirect, "/user/login"};
                        true -> {ok, Person}
                    end
            end
     end.

check_user(Req) ->
    case Req:cookie("user_id") of
		  undefined -> {ok, undefined};
        Id ->
            case boss_db:find(Id) of
					 undefined -> {ok, undefined};
                Person ->
                    case Person:session_identifier() =:= Req:cookie("session_id") of
								false -> {ok, undefined};
                        true -> {ok, Person}
                    end
            end
     end.
