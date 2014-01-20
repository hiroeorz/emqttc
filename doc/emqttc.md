

# Module emqttc #
* [Function Index](#index)
* [Function Details](#functions)


<a name="index"></a>

## Function Index ##


<table width="100%" border="1" cellspacing="0" cellpadding="2" summary="function index"><tr><td valign="top"><a href="#code_change-4">code_change/4</a></td><td></td></tr><tr><td valign="top"><a href="#connected-2">connected/2</a></td><td></td></tr><tr><td valign="top"><a href="#connected-3">connected/3</a></td><td></td></tr><tr><td valign="top"><a href="#connecting-2">connecting/2</a></td><td></td></tr><tr><td valign="top"><a href="#connecting-3">connecting/3</a></td><td></td></tr><tr><td valign="top"><a href="#disconnect-1">disconnect/1</a></td><td></td></tr><tr><td valign="top"><a href="#handle_event-3">handle_event/3</a></td><td></td></tr><tr><td valign="top"><a href="#handle_info-3">handle_info/3</a></td><td></td></tr><tr><td valign="top"><a href="#handle_sync_event-4">handle_sync_event/4</a></td><td></td></tr><tr><td valign="top"><a href="#init-1">init/1</a></td><td></td></tr><tr><td valign="top"><a href="#ping-1">ping/1</a></td><td></td></tr><tr><td valign="top"><a href="#puback-2">puback/2</a></td><td></td></tr><tr><td valign="top"><a href="#pubcomp-2">pubcomp/2</a></td><td></td></tr><tr><td valign="top"><a href="#publish-2">publish/2</a></td><td></td></tr><tr><td valign="top"><a href="#publish-3">publish/3</a></td><td></td></tr><tr><td valign="top"><a href="#pubrec-2">pubrec/2</a></td><td></td></tr><tr><td valign="top"><a href="#start-0">start/0</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-0">start_link/0</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-1">start_link/1</a></td><td></td></tr><tr><td valign="top"><a href="#start_link-2">start_link/2</a></td><td></td></tr><tr><td valign="top"><a href="#subscribe-2">subscribe/2</a></td><td></td></tr><tr><td valign="top"><a href="#terminate-3">terminate/3</a></td><td></td></tr><tr><td valign="top"><a href="#test_sub-0">test_sub/0</a></td><td></td></tr><tr><td valign="top"><a href="#unsubscribe-2">unsubscribe/2</a></td><td></td></tr><tr><td valign="top"><a href="#waiting_for_connack-2">waiting_for_connack/2</a></td><td></td></tr></table>


<a name="functions"></a>

## Function Details ##

<a name="code_change-4"></a>

### code_change/4 ###

`code_change(OldVsn, StateName, State, Extra) -> any()`


<a name="connected-2"></a>

### connected/2 ###

`connected(Event, State) -> any()`


<a name="connected-3"></a>

### connected/3 ###

`connected(Event, From, State) -> any()`


<a name="connecting-2"></a>

### connecting/2 ###

`connecting(Event, State) -> any()`


<a name="connecting-3"></a>

### connecting/3 ###

`connecting(Event, From, State) -> any()`


<a name="disconnect-1"></a>

### disconnect/1 ###

`disconnect(C) -> any()`


<a name="handle_event-3"></a>

### handle_event/3 ###

`handle_event(Event, StateName, State) -> any()`


<a name="handle_info-3"></a>

### handle_info/3 ###

`handle_info(Info, StateName, State) -> any()`


<a name="handle_sync_event-4"></a>

### handle_sync_event/4 ###

`handle_sync_event(X1, From, StateName, State) -> any()`


<a name="init-1"></a>

### init/1 ###

`init(X1) -> any()`


<a name="ping-1"></a>

### ping/1 ###

`ping(C) -> any()`


<a name="puback-2"></a>

### puback/2 ###

`puback(C, MsgId) -> any()`


<a name="pubcomp-2"></a>

### pubcomp/2 ###

`pubcomp(C, MsgId) -> any()`


<a name="publish-2"></a>

### publish/2 ###

`publish(C, Msg) -> any()`


<a name="publish-3"></a>

### publish/3 ###

`publish(C, Topic, Payload) -> any()`


<a name="pubrec-2"></a>

### pubrec/2 ###

`pubrec(C, MsgId) -> any()`


<a name="start-0"></a>

### start/0 ###

`start() -> any()`


<a name="start_link-0"></a>

### start_link/0 ###

`start_link() -> any()`


<a name="start_link-1"></a>

### start_link/1 ###

`start_link(Opts) -> any()`


<a name="start_link-2"></a>

### start_link/2 ###

`start_link(Name, Opts) -> any()`


<a name="subscribe-2"></a>

### subscribe/2 ###

`subscribe(C, Topics) -> any()`


<a name="terminate-3"></a>

### terminate/3 ###

`terminate(Reason, StateName, State) -> any()`


<a name="test_sub-0"></a>

### test_sub/0 ###

`test_sub() -> any()`


<a name="unsubscribe-2"></a>

### unsubscribe/2 ###

`unsubscribe(C, Topics) -> any()`


<a name="waiting_for_connack-2"></a>

### waiting_for_connack/2 ###

`waiting_for_connack(Event, State) -> any()`


