
-module(emqttc_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type), {I, {I, start_link, []}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([]) ->
    SubEvent = {emqttc_sub_event, {emqttc_sub_event, start_link, []},
		permanent, 2000, worker, [emqttc_sub_event]},

    {ok, { {one_for_one, 5, 10}, [SubEvent]} }.

