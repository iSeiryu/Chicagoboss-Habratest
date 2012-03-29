-module(addressbook_chat_controller, [Req]).
-compile(export_all).

% Chicago Boss checks to see if the controller has an before_ function. If so, it passes the action name to the before_ function and checks the return value.
before_(_) ->
    user_lib:check_user(Req).

login('GET', [Username]) ->
    create_and_push_message("public", string:concat(Username, " joined the room"), "system"),
    {json, [{chatuserid, create_user(Username)}]}.

logout('GET', [Username, UserId]) ->
	 boss_db:delete(UserId),
    create_and_push_message("public", string:concat(Username, " left the room"), "system"),
    {output, "ok"}.

live('GET', [Channel], Person) ->
    Timestamp = boss_mq:now(Channel),
    {ok, [{timestamp, Timestamp}, {channel, Channel}, {ip, Req:peer_ip()}, {person, Person}]}.

send_message('POST', [Channel]) ->
    create_and_push_message(Channel, list_to_binary(Req:post_param("message")), Req:post_param("nickname")),
    {output, "ok"}.

receive_chat('GET', [Channel, LastTimestamp, UserlistCount]) ->
	 case boss_db:count(userlist) == UserlistCount of
	 	true ->
	 		Users = undefined;
 		false ->
 			Users = boss_db:find(userlist,[])
	 end,
    {ok, Timestamp, Messages} = boss_mq:pull(Channel, list_to_integer(LastTimestamp)),
    {json, [{timestamp, Timestamp}, {messages, Messages}, {users, Users}]}.

send_test_message('GET', []) ->
    create_and_push_message("public", "This is a test message from the browser", "TestUser"),
    {output, "Message sent"}.

%% Utility methods
create_and_push_message(Channel, Message, Username) ->
    NewMessage = message:new(id, Message, Username, erlang:localtime()),
    boss_mq:push(Channel, NewMessage).

create_user(Username) ->
	NewUser = userlist:new(id, Username),
	case NewUser:save() of
		{ok, SavedUser} ->
			SavedUser:id();
		{error, Reason} ->
			undefined
	end.
