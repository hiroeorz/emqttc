-module(emqttc).
-behavior(gen_fsm).

-include("emqtt_frame.hrl").

%% start application.
-export([start/0]).

%startup
-export([start_link/0,
	 start_link/1,
	 start_link/2]).

%api
-export([publish/2, publish/3,
	 puback/2,
	 pubrec/2,
	 pubcomp/2,
	 subscribe/2,
	 unsubscribe/2,
	 ping/1,
	 disconnect/1]).


%% gen_fsm callbacks
-export([init/1,
	 handle_info/3,
	 handle_event/3,
	 handle_sync_event/4,
	 code_change/4,
	 terminate/3]).

% fsm state
-export([connecting/2,
	 connecting/3,
	 waiting_for_connack/2,
	 connected/2,
	 connected/3]).

-define(TCPOPTIONS, [binary,
		     {packet,    raw},
		     {reuseaddr, true},
		     {nodelay,   true},
		     {active, 	true},
		     {reuseaddr, true},
		     {send_timeout,  3000}]).

-define(TIMEOUT, 3000).

-record(state, {host      :: inet:ip_address(),
		port      :: inet:port_number(),
		sock      :: gen_tcp:socket(),
		msgid = 0 :: non_neg_integer(),
		username  :: binary(),
		password  :: binary() }).

%%--------------------------------------------------------------------
%% @doc start application
%% @end
%%--------------------------------------------------------------------
-spec start() -> ok.
start() ->
    application:start(emqttc).

%%--------------------------------------------------------------------
%% @doc Starts the server
%% @end
%%--------------------------------------------------------------------
-spec start_link() -> {ok, pid()} | ignore | {error, term()}.
start_link() ->
    start_link([]).

%%--------------------------------------------------------------------
%% @doc Starts the server with options.
%% @end
%%--------------------------------------------------------------------
-spec start_link([tuple()]) -> {ok, pid()} | ignore | {error, term()}.
start_link(Opts) when is_list(Opts) ->
    start_link(emqttc, Opts).

%%--------------------------------------------------------------------
%% @doc Starts the server with name and options.
%% @end
%%--------------------------------------------------------------------
-spec start_link(atom(), [tuple()]) -> {ok, pid()} | ignore | {error, term()}.
start_link(Name, Opts) when is_atom(Name), is_list(Opts) ->
    gen_fsm:start_link({local, Name}, ?MODULE, [Name, Opts], []).

%%--------------------------------------------------------------------
%% @doc publish to broker.
%% @end
%%--------------------------------------------------------------------
-spec publish(C, Topic, Payload) -> ok when
      C :: pid() | atom(),
      Topic :: binary(),
      Payload :: binary().
publish(C, Topic, Payload) ->
    publish(C, #mqtt_msg{topic = Topic, payload = Payload}).

-spec publish(C, #mqtt_msg{}) -> ok when
      C :: pid() | atom().			       
publish(C, Msg) when is_record(Msg, mqtt_msg) ->
    gen_fsm:send_event(C, {publish, Msg}).

%%--------------------------------------------------------------------
%% @doc puback to broker.
%% @end
%%--------------------------------------------------------------------
-spec puback(C, MsgId) -> ok when
      C :: pid() | atom(),
      MsgId :: non_neg_integer().      
puback(C, MsgId) when is_integer(MsgId) ->
    gen_fsm:send_event(C, {puback, MsgId}).

%%--------------------------------------------------------------------
%% @doc pubrec to broker.
%% @end
%%--------------------------------------------------------------------
-spec pubrec(C, MsgId) -> ok when
      C :: pid() | atom(),
      MsgId :: non_neg_integer().
pubrec(C, MsgId) when is_integer(MsgId) ->
    gen_fsm:send_event(C, {pubrec, MsgId}).

%%--------------------------------------------------------------------
%% @doc pubcomp.
%% @end
%%--------------------------------------------------------------------
-spec pubcomp(C, MsgId) -> ok when
      C :: pid() | atom(),
      MsgId :: non_neg_integer().
pubcomp(C, MsgId) when is_integer(MsgId) ->
    gen_fsm:send_event(C, {pubcomp, MsgId}).

%%--------------------------------------------------------------------
%% @doc subscribe request to broker.
%% @end
%%--------------------------------------------------------------------
-spec subscribe(C, Topics) -> ok when
      C :: pid() | atom(),
      Topics :: [ {binary(), non_neg_integer()} ].
subscribe(C, Topics) ->
    gen_fsm:send_event(C, {subscribe, Topics}).

%%--------------------------------------------------------------------
%% @doc unsubscribe request to broker.
%% @end
%%--------------------------------------------------------------------
-spec unsubscribe(C, Topics) -> ok when
      C :: pid() | atom(),
      Topics :: [ {binary(), non_neg_integer()} ].
unsubscribe(C, Topics) ->
    gen_fsm:send_event(C, {unsubscribe, Topics}).

%%--------------------------------------------------------------------
%% @doc Send ping to broker.
%% @end
%%--------------------------------------------------------------------
-spec ping(C) -> ok when
      C :: pid() | atom().
ping(C) ->
    gen_fsm:send_event(C, ping).

%%--------------------------------------------------------------------
%% @doc Disconnect from broker.
%% @end
%%--------------------------------------------------------------------
-spec disconnect(C) -> ok when
      C :: pid() | atom().
disconnect(C) ->
    gen_fsm:send_event(C, disconnect).

%%gen_fsm callbacks
init([_Name, Args]) ->
    Host = proplists:get_value(host, Args, "localhost"),
    Port = proplists:get_value(port, Args, 1883),
    Username = proplists:get_value(username, Args, undefined),
    Password = proplists:get_value(password, Args, undefined),
    State = #state{host = Host, port = Port,
		   username = Username, password = Password},
    {ok, connecting, State, 0}.

connecting(timeout, State) ->
    connect(State);

connecting(_Event, State) ->
    {next_state, connecting, State}.

connecting(_Event, _From, State) ->
    {reply, {error, connecting}, connecting, State}.

connect(#state{host = Host, port = Port} = State) ->
    io:format("connecting to ~p:~p~n", [Host, Port]),

    case gen_tcp:connect(Host, Port, ?TCPOPTIONS, ?TIMEOUT) of
	{ok, Sock} ->
	    io:format("tcp connected.~n"),
	    NewState = State#state{sock = Sock},
	    send_connect(NewState),
	    {next_state, waiting_for_connack, NewState};
	{error, Reason} ->
	    io:format("tcp connection failure: ~p~n", [Reason]),
	    reconnect(),
	    {next_state, connecting, State#state{sock = undefined}}
    end.

send_connect(#state{sock=Sock, username=Username, password=Password}) ->
    Frame = 
	#mqtt_frame{
	   fixed = #mqtt_frame_fixed{
		      type = ?CONNECT,
		      dup = 0,
		      qos = 1,
		      retain = 0},
	   variable = #mqtt_frame_connect{
			 username   = Username,
			 password   = Password,
			 proto_ver  = ?MQTT_PROTO_MAJOR,
			 clean_sess = true,
			 keep_alive = 60,
			 client_id  = "emqttc"}},
    send_frame(Sock, Frame).

waiting_for_connack(_Event, State) ->
    %FIXME:
    {next_state, waiting_for_connack, State}.

connected({publish, Msg}, State=#state{sock=Sock, msgid=MsgId}) ->
    #mqtt_msg{retain     = Retain,
	      qos        = Qos,
	      topic      = Topic,
	      dup        = Dup,
	      payload    = Payload} = Msg,
    Frame = #mqtt_frame{
	       fixed = #mqtt_frame_fixed{type 	 = ?PUBLISH,
					 qos    = Qos,
					 retain = Retain,
					 dup    = Dup},
	       variable = #mqtt_frame_publish{topic_name = Topic,
					      message_id = if
							       Qos == ?QOS_0 -> undefined;
							       true -> MsgId
							   end},
	       payload = Payload},
    send_frame(Sock, Frame),
    {next_state, connected, State#state{msgid=MsgId+1}};

connected({puback, MsgId}, State=#state{sock=Sock}) ->
    send_puback(Sock, ?PUBACK, MsgId),
    {next_state, connected, State};

connected({pubrec, MsgId}, State=#state{sock=Sock}) ->
    send_puback(Sock, ?PUBREC, MsgId),
    {next_state, connected, State};

connected({pubrel, MsgId}, State=#state{sock=Sock}) ->
    send_puback(Sock, ?PUBREL, MsgId),
    {next_state, connected, State};

connected({pubcomp, MsgId}, State=#state{sock=Sock}) ->
    send_puback(Sock, ?PUBCOMP, MsgId),
    {next_state, connected, State};

connected(ping, State=#state{sock=Sock}) ->
    send_ping(Sock),
    {next_state, connected, State};

connected({subscribe, Topics}, State=#state{msgid=MsgId,sock=Sock}) ->
    Topics1 = [#mqtt_topic{name=Topic, qos=Qos} || {Topic, Qos} <- Topics],
    Frame = #mqtt_frame{
	       fixed = #mqtt_frame_fixed{type = ?SUBSCRIBE,
					 dup = 0,
					 qos = 1,
					 retain = 0},
	       variable = #mqtt_frame_subscribe{message_id  = MsgId,
						topic_table = Topics1}},
    send_frame(Sock, Frame),
    {next_state, connected, State#state{msgid=MsgId+1}};

connected({unsubscribe, Topics}, State=#state{sock=Sock, msgid=MsgId}) ->
    Frame = #mqtt_frame{
	       fixed = #mqtt_frame_fixed{type = ?UNSUBSCRIBE,
					 dup = 0,
					 qos = 1,
					 retain = 0},
	       variable = MsgId,
	       payload = Topics},
    send_frame(Sock, Frame),
    {next_state, connected, State};

connected(disconnect, State=#state{sock=Sock}) ->
    send_disconnect(Sock),
    {next_state, connected, State};

connected(_Event, State) -> 
    {next_state, connected, State}.

connected(Event, _From, State) ->
    io:format("unsupported event: ~p~n", [Event]),
    {reply, {error, unsupport}, connected, State}.

reconnect() ->
    %%FIXME
    erlang:send_after(30000, self(), {timeout, reconnect}).

%% connack message from broker.
handle_info({tcp, _Sock, <<?CONNACK:4/integer, _:4/integer, 2:8/integer,
			 _:8/integer, ReturnCode:8/unsigned-integer>>},
	    waiting_for_connack, State) ->
    case ReturnCode of
	?CONNACK_ACCEPT ->
	    io:format("connack: Connection Accepted~n"),
	    {next_state, connected, State};
	?CONNACK_PROTO_VER ->
	    io:format("connack: NG(unacceptable protocol version)~n"),
	    {next_state, waiting_for_connack, State};
	?CONNACK_INVALID_ID ->
	    io:format("connack: NG(identifier rejected)~n"),
	    {next_state, waiting_for_connack, State};
	?CONNACK_SERVER ->
	    io:format("connack: NG(server unavailable)~n"),
	    {next_state, waiting_for_connack, State};
	?CONNACK_CREDENTIALS ->
	    io:format("connack: NG(bad user name or password)~n"),
	    {next_state, waiting_for_connack, State};
	?CONNACK_AUTH ->
	    io:format("connack: NG(not authorized)~n"),
	    {next_state, waiting_for_connack, State}
    end;

%% suback message from broker.
handle_info({tcp, _Sock, <<?SUBACK:4/integer, _:4/integer, _/binary>>},
	    connected, State) ->
    {next_state, connected, State};

%% pub message from broker(QoS = 0).
handle_info({tcp, _Sock, <<?PUBLISH:4/integer,
			   _:1/integer, ?QOS_0:2/integer, _:1/integer,
			   _Len:8/integer,
			   TopicSize:16/big-unsigned-integer,
			   Topic:TopicSize/binary,
			   Payload/binary>>},
	    connected, State) ->
    gen_event:notify(emqttc_event, {publish, Topic, Payload}),
    {next_state, connected, State};

%% pub message from broker(QoS = 1 or 2).
handle_info({tcp, _Sock, <<?PUBLISH:4/integer,
			   _:1/integer, Qos:2/integer, _:1/integer,
			   _Len:8/integer,
			   TopicSize:16/big-unsigned-integer,
			   Topic:TopicSize/binary,
			   MsgId:16/big-unsigned-integer,
			   Payload/binary>>},
	    connected, State) when Qos =:= ?QOS_1; Qos =:= ?QOS_2 ->
    gen_event:notify(emqttc_event, {publish, Topic, Payload, Qos, MsgId}),
    {next_state, connected, State};

%% pubrec message from broker.
handle_info({tcp, _Sock, <<?PUBACK:4/integer,
			   _:1/integer, _:2/integer, _:1/integer,
			   2:8/integer,
			   MsgId:16/big-unsigned-integer>>},
	    connected, State) ->
    gen_event:notify(emqttc_event, {puback, MsgId}),
    {next_state, connected, State};

%% pubrec message from broker.
handle_info({tcp, _Sock, <<?PUBREC:4/integer,
			   _:1/integer, _:2/integer, _:1/integer,
			   2:8/integer,
			   MsgId:16/big-unsigned-integer>>},
	    connected, State) ->
    gen_event:notify(emqttc_event, {pubrec, MsgId}),
    {next_state, connected, State};

%% pubcomp message from broker.
handle_info({tcp, _Sock, <<?PUBCOMP:4/integer,
			   _:1/integer, _:2/integer, _:1/integer,
			   2:8/integer,
			   MsgId:16/big-unsigned-integer>>},
	    connected, State) ->
    gen_event:notify(emqttc_event, {pubcomp, MsgId}),
    {next_state, connected, State};

%% pingresp message from broker.
handle_info({tcp, _Sock, <<?PINGRESP:4/integer,
			   _:1/integer, _:2/integer, _:1/integer,
			   0:8/integer>>},
	    connected, State) ->
    gen_event:notify(emqttc_event, {pingresp}),
    {next_state, connected, State};

handle_info({tcp, _Sock, Data}, connected, State) ->
    <<Code:4/integer, _:4/integer, _/binary>> = Data,
    io:format("data received from remote(code:~w): ~p~n", [Code, Data]),
    {next_state, connected, State};

handle_info({tcp_closed, Sock}, connected, State=#state{sock=Sock}) ->
    {next_state, disconnected, State};

handle_info({timeout, reconnect}, connecting, S) ->
    connect(S);

handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

handle_sync_event(status, _From, StateName, State) ->
    Statistics = [{N, get(N)} || N <- [inserted]],
    {reply, {StateName, Statistics}, StateName, State};

handle_sync_event(stop, _From, _StateName, State) ->
    {stop, normal, ok, State}.

terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

send_puback(Sock, _Type, MsgId) ->
    Frame = #mqtt_frame{
	       fixed = #mqtt_frame_fixed{type = ?PUBACK},
	       variable = #mqtt_frame_publish{message_id = MsgId}},
    send_frame(Sock, Frame).

send_disconnect(Sock) ->
    Frame = #mqtt_frame{
	       fixed = #mqtt_frame_fixed{type = ?DISCONNECT,
					 qos = 0,
					 retain = 0,
					 dup = 0}},
    send_frame(Sock, Frame).

send_ping(Sock) ->
    Frame = #mqtt_frame{
	       fixed = #mqtt_frame_fixed{type = ?PINGREQ,
					 qos = 1,
					 retain = 0,
					 dup = 0}},
    send_frame(Sock, Frame).

send_frame(Sock, Frame) ->
    erlang:port_command(Sock, emqtt_frame:serialise(Frame)).

