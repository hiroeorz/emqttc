# emqttc

erlang mqtt client.

## Build

```
$ make
```

## Start Application

```erl-sh
1> application:start(emqttc).
```

## Subscribe and Publush

Connect to MQTT Broker.

```erl-sh
1> emqttc:start_link([{host, "test.mosquitto.org"}]).

%% publish.
2> emqttc:publish(emqttc, <<"temp/random">>, <<"0">>).

%% subscribe.
3> Qos = 0.
4> emqttc:subscribe(emqttc, [{<<"temp/random">>, Qos}]).

%% add event handler.
5> emqttc_sub_event:add_handler().
```

You can add your custom event handler.

```
1> emqttc_sub_event:add_handler(your_handler, []).
```
