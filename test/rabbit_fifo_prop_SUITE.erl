-module(rabbit_fifo_prop_SUITE).

-compile(export_all).

-export([
         ]).

-include_lib("proper/include/proper.hrl").
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("ra/include/ra.hrl").
-include("src/rabbit_fifo.hrl").

%%%===================================================================
%%% Common Test callbacks
%%%===================================================================

all() ->
    [
     {group, tests}
    ].


all_tests() ->
    [
     test_run_log,
     snapshots,
     scenario1,
     scenario2,
     scenario3,
     scenario4,
     scenario5,
     scenario6,
     scenario7,
     scenario8,
     scenario9,
     scenario10,
     scenario11,
     scenario12,
     scenario13,
     scenario14,
     scenario15,
     scenario16,
     scenario17,
     single_active,
     single_active_01,
     single_active_02,
     single_active_03,
     single_active_ordering,
     single_active_ordering_01
     % single_active_ordering_02
    ].

groups() ->
    [
     {tests, [], all_tests()}
    ].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_group(_Group, Config) ->
    Config.

end_per_group(_Group, _Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    Config.

end_per_testcase(_TestCase, _Config) ->
    ok.

%%%===================================================================
%%% Test cases
%%%===================================================================

% -type log_op() ::
%     {enqueue, pid(), maybe(msg_seqno()), Msg :: raw_msg()}.

scenario1(_Config) ->
    C1 = {<<>>, c:pid(0,6723,1)},
    C2 = {<<0>>,c:pid(0,6723,1)},
    E = c:pid(0,6720,1),

    Commands = [
                make_checkout(C1, {auto,2,simple_prefetch}),
                make_enqueue(E,1,msg1),
                make_enqueue(E,2,msg2),
                make_checkout(C1, cancel), %% both on returns queue
                make_checkout(C2, {auto,1,simple_prefetch}),
                make_return(C2, [0]), %% E1 in returns, E2 with C2
                make_return(C2, [1]), %% E2 in returns E1 with C2
                make_settle(C2, [2]) %% E2 with C2
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME}, Commands),
    ok.

scenario2(_Config) ->
    C1 = {<<>>, c:pid(0,346,1)},
    C2 = {<<>>,c:pid(0,379,1)},
    E = c:pid(0,327,1),
    Commands = [make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,1,msg1),
                make_checkout(C1, cancel),
                make_enqueue(E,2,msg2),
                make_checkout(C2, {auto,1,simple_prefetch}),
                make_settle(C1, [0]),
                make_settle(C2, [0])
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME}, Commands),
    ok.

scenario3(_Config) ->
    C1 = {<<>>, c:pid(0,179,1)},
    E = c:pid(0,176,1),
    Commands = [make_checkout(C1, {auto,2,simple_prefetch}),
                make_enqueue(E,1,msg1),
                make_return(C1, [0]),
                make_enqueue(E,2,msg2),
                make_enqueue(E,3,msg3),
                make_settle(C1, [1]),
                make_settle(C1, [2])
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME}, Commands),
    ok.

scenario4(_Config) ->
    C1 = {<<>>, c:pid(0,179,1)},
    E = c:pid(0,176,1),
    Commands = [make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,1,msg),
                make_settle(C1, [0])
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME}, Commands),
    ok.

scenario5(_Config) ->
    C1 = {<<>>, c:pid(0,505,0)},
    E = c:pid(0,465,9),
    Commands = [make_enqueue(E,1,<<0>>),
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,2,<<>>),
                make_settle(C1,[0])],
    run_snapshot_test(#{name => ?FUNCTION_NAME}, Commands),
    ok.

scenario6(_Config) ->
    E = c:pid(0,465,9),
    Commands = [make_enqueue(E,1,<<>>), %% 1 msg on queue - snap: prefix 1
                make_enqueue(E,2,<<>>) %% 1. msg on queue - snap: prefix 1
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_length => 1}, Commands),
    ok.

scenario7(_Config) ->
    C1 = {<<>>, c:pid(0,208,0)},
    E = c:pid(0,188,0),
    Commands = [
                make_enqueue(E,1,<<>>),
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,2,<<>>),
                make_enqueue(E,3,<<>>),
                make_settle(C1,[0])],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_length => 1}, Commands),
    ok.

scenario8(_Config) ->
    C1 = {<<>>, c:pid(0,208,0)},
    E = c:pid(0,188,0),
    Commands = [
                make_enqueue(E,1,<<>>),
                make_enqueue(E,2,<<>>),
                make_checkout(C1, {auto,1,simple_prefetch}),
                % make_checkout(C1, cancel),
                {down, E, noconnection},
                make_settle(C1, [0])],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_length => 1}, Commands),
    ok.

scenario9(_Config) ->
    E = c:pid(0,188,0),
    Commands = [
                make_enqueue(E,1,<<>>),
                make_enqueue(E,2,<<>>),
                make_enqueue(E,3,<<>>)],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_length => 1}, Commands),
    ok.

scenario10(_Config) ->
    C1 = {<<>>, c:pid(0,208,0)},
    E = c:pid(0,188,0),
    Commands = [
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,1,<<>>),
                make_settle(C1, [0])
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_length => 1}, Commands),
    ok.

scenario11(_Config) ->
    C1 = {<<>>, c:pid(0,215,0)},
    E = c:pid(0,217,0),
    Commands = [
                make_enqueue(E,1,<<>>),
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_checkout(C1, cancel),
                make_enqueue(E,2,<<>>),
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_settle(C1, [0]),
                make_checkout(C1, cancel)
                ],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_length => 2}, Commands),
    ok.

scenario12(_Config) ->
    E = c:pid(0,217,0),
    Commands = [make_enqueue(E,1,<<0>>),
                make_enqueue(E,2,<<0>>),
                make_enqueue(E,3,<<0>>)],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_bytes => 2}, Commands),
    ok.

scenario13(_Config) ->
    E = c:pid(0,217,0),
    Commands = [make_enqueue(E,1,<<0>>),
                make_enqueue(E,2,<<>>),
                make_enqueue(E,3,<<>>),
                make_enqueue(E,4,<<>>)
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_length => 2}, Commands),
    ok.

scenario14(_Config) ->
    E = c:pid(0,217,0),
    Commands = [make_enqueue(E,1,<<0,0>>)],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        max_bytes => 1}, Commands),
    ok.

scenario15(_Config) ->
    C1 = {<<>>, c:pid(0,179,1)},
    E = c:pid(0,176,1),
    Commands = [make_checkout(C1, {auto,2,simple_prefetch}),
                make_enqueue(E, 1, msg1),
                make_enqueue(E, 2, msg2),
                make_return(C1, [0]),
                make_return(C1, [2]),
                make_settle(C1, [1])
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        delivery_limit => 1}, Commands),
    ok.

scenario16(_Config) ->
    C1Pid = c:pid(0,883,1),
    C1 = {<<>>, C1Pid},
    C2 = {<<>>, c:pid(0,882,1)},
    E = c:pid(0,176,1),
    Commands = [
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E, 1, msg1),
                make_checkout(C2, {auto,1,simple_prefetch}),
                {down, C1Pid, noproc}, %% msg1 allocated to C2
                make_return(C2, [0]), %% msg1 returned
                make_enqueue(E, 2, <<>>),
                make_settle(C2, [0])
               ],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        delivery_limit => 1}, Commands),
    ok.

scenario17(_Config) ->
    C1Pid = test_util:fake_pid(rabbit@fake_node1),
    C1 = {<<0>>, C1Pid},
    % C2Pid = test_util:fake_pid(fake_node1),
    C2 = {<<>>, C1Pid},
    E = test_util:fake_pid(rabbit@fake_node2),
    Commands = [
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,1,<<"one">>),
                make_checkout(C2, {auto,1,simple_prefetch}),
                {down, C1Pid, noconnection},
                make_checkout(C2, cancel),
                make_enqueue(E,2,<<"two">>),
                {nodeup,rabbit@fake_node1},
                %% this has no effect as was returned
                make_settle(C1, [0]),
                %% this should settle "one"
                make_settle(C1, [1])
                ],
    run_snapshot_test(#{name => ?FUNCTION_NAME,
                        single_active_consumer_on => true
                       }, Commands),
    ok.

single_active_01(_Config) ->
    C1Pid = test_util:fake_pid(rabbit@fake_node1),
    C1 = {<<0>>, C1Pid},
    C2Pid = test_util:fake_pid(rabbit@fake_node2),
    C2 = {<<>>, C2Pid},
    E = test_util:fake_pid(rabbit@fake_node2),
    Commands = [
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,1,<<"one">>),
                make_checkout(C2, {auto,1,simple_prefetch}),
                make_checkout(C1, cancel),
                {nodeup,rabbit@fake_node1}
                ],
    ?assert(
       single_active_prop(#{name => ?FUNCTION_NAME,
                            single_active_consumer_on => true
                       }, Commands, false)),
    ok.

single_active_02(_Config) ->
    C1Pid = test_util:fake_pid(node()),
    C1 = {<<0>>, C1Pid},
    C2Pid = test_util:fake_pid(node()),
    C2 = {<<>>, C2Pid},
    E = test_util:fake_pid(node()),
    Commands = [
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E,1,<<"one">>),
                {down,E,noconnection},
                make_checkout(C2, {auto,1,simple_prefetch}),
                make_checkout(C2, cancel),
                {down,E,noconnection}
                ],
    Conf = config(?FUNCTION_NAME, undefined, undefined, true, 1),
    ?assert(single_active_prop(Conf, Commands, false)),
    ok.

single_active_03(_Config) ->
    C1Pid = test_util:fake_pid(node()),
    C1 = {<<0>>, C1Pid},
    % C2Pid = test_util:fake_pid(rabbit@fake_node2),
    % C2 = {<<>>, C2Pid},
    Pid = test_util:fake_pid(node()),
    E = test_util:fake_pid(rabbit@fake_node2),
    Commands = [
                make_checkout(C1, {auto,2,simple_prefetch}),
                make_enqueue(E, 1, 0),
                make_enqueue(E, 2, 1),
                {down, Pid, noconnection},
                {nodeup, node()}
                ],
    Conf = config(?FUNCTION_NAME, 0, 0, true, 0),
    ?assert(single_active_prop(Conf, Commands, true)),
    ok.

test_run_log(_Config) ->
    Fun = {-1, fun ({Prev, _}) -> {Prev + 1, Prev + 1} end},
    run_proper(
      fun () ->
              ?FORALL({Length, Bytes, SingleActiveConsumer, DeliveryLimit},
                      frequency([{10, {0, 0, false, 0}},
                                 {5, {oneof([range(1, 10), undefined]),
                                      oneof([range(1, 1000), undefined]),
                                      boolean(),
                                      oneof([range(1, 3), undefined])
                                     }}]),
                      ?FORALL(O, ?LET(Ops, log_gen(100), expand(Ops, Fun)),
                              collect({log_size, length(O)},
                                      dump_generated(
                                        config(?FUNCTION_NAME,
                                               Length,
                                               Bytes,
                                               SingleActiveConsumer,
                                               DeliveryLimit), O))))
      end, [], 10).

snapshots(_Config) ->
    run_proper(
      fun () ->
              ?FORALL({Length, Bytes, SingleActiveConsumer, DeliveryLimit},
                      frequency([{10, {0, 0, false, 0}},
                                 {5, {oneof([range(1, 10), undefined]),
                                      oneof([range(1, 1000), undefined]),
                                      boolean(),
                                      oneof([range(1, 3), undefined])
                                     }}]),
                      ?FORALL(O, ?LET(Ops, log_gen(250), expand(Ops)),
                              collect({log_size, length(O)},
                                      snapshots_prop(
                                        config(?FUNCTION_NAME,
                                               Length,
                                               Bytes,
                                               SingleActiveConsumer,
                                               DeliveryLimit), O))))
      end, [], 2500).

single_active(_Config) ->
    Size = 2000,
    run_proper(
      fun () ->
              ?FORALL({Length, Bytes, DeliveryLimit},
                      frequency([{10, {0, 0, 0}},
                                 {5, {oneof([range(1, 10), undefined]),
                                      oneof([range(1, 1000), undefined]),
                                      oneof([range(1, 3), undefined])
                                     }}]),
                      ?FORALL(O, ?LET(Ops, log_gen(Size), expand(Ops)),
                              collect({log_size, length(O)},
                                      single_active_prop(
                                        config(?FUNCTION_NAME,
                                               Length,
                                               Bytes,
                                               true,
                                               DeliveryLimit), O,
                                        false))))
      end, [], Size).

single_active_ordering(_Config) ->
    Size = 2000,
    Fun = {-1, fun ({Prev, _}) -> {Prev + 1, Prev + 1} end},
    run_proper(
      fun () ->
              ?FORALL(O, ?LET(Ops, log_gen_ordered(Size), expand(Ops, Fun)),
                      collect({log_size, length(O)},
                              single_active_prop(config(?FUNCTION_NAME,
                                                        undefined,
                                                        undefined,
                                                        true,
                                                        undefined), O,
                                                 true)))
      end, [], Size).

single_active_ordering_01(_Config) ->
% [{enqueue,<0.145.0>,1,0},
%  {enqueue,<0.145.0>,1,1},
%  {checkout,{<<>>,<0.148.0>},{auto,1,simple_prefetch},#{ack => true,args => [],prefetch => 1,username => <<117,115,101,114>>}}
%  {enqueue,<0.140.0>,1,2},
%  {settle,{<<>>,<0.148.0>},[0]}]
    C1Pid = test_util:fake_pid(node()),
    C1 = {<<0>>, C1Pid},
    E = test_util:fake_pid(rabbit@fake_node2),
    E2 = test_util:fake_pid(rabbit@fake_node2),
    Commands = [
                make_enqueue(E, 1, 0),
                make_enqueue(E, 2, 1),
                make_checkout(C1, {auto,2,simple_prefetch}),
                make_enqueue(E2, 1, 2),
                make_settle(C1, [0])
                ],
    Conf = config(?FUNCTION_NAME, 0, 0, true, 0),
    ?assert(single_active_prop(Conf, Commands, true)),
    ok.

single_active_ordering_02(_Config) ->
    %% this results in the pending enqueue being enqueued and violating
    %% ordering
% [{checkout, %   {<<>>,<0.177.0>}, %   {auto,1,simple_prefetch},
%  {enqueue,<0.172.0>,2,1},
%  {down,<0.172.0>,noproc},
%  {settle,{<<>>,<0.177.0>},[0]}]
    C1Pid = test_util:fake_pid(node()),
    C1 = {<<0>>, C1Pid},
    E = test_util:fake_pid(node()),
    Commands = [
                make_checkout(C1, {auto,1,simple_prefetch}),
                make_enqueue(E, 2, 1),
                %% CANNOT HAPPEN
                {down,E,noproc},
                make_settle(C1, [0])
                ],
    Conf = config(?FUNCTION_NAME, 0, 0, true, 0),
    ?assert(single_active_prop(Conf, Commands, true)),
    ok.

config(Name, Length, Bytes, SingleActive, DeliveryLimit) ->
    #{name => Name,
      max_length => map_max(Length),
      max_bytes => map_max(Bytes),
      single_active_consumer_on => SingleActive,
      delivery_limit => map_max(DeliveryLimit)}.

map_max(0) -> undefined;
map_max(N) -> N.

single_active_prop(Conf0, Commands, ValidateOrder) ->
    Conf = Conf0#{release_cursor_interval => 100},
    Indexes = lists:seq(1, length(Commands)),
    Entries = lists:zip(Indexes, Commands),
    %% invariant: there can only be one active consumer at any one time
    %% there can however be multiple cancelled consumers
    Invariant = fun (#rabbit_fifo{consumers = Consumers}) ->
                        Up = maps:filter(fun (_, #consumer{status = S}) ->
                                                 S == up
                                         end, Consumers),
                        map_size(Up) =< 1
                end,
    try run_log(test_init(Conf), Entries, Invariant) of
        {_State, Effects} when ValidateOrder ->
            %% validate message ordering
            lists:foldl(fun ({send_msg, Pid, {delivery, Tag, Msgs}, ra_event},
                             Acc) ->
                                validate_msg_order({Tag, Pid}, Msgs, Acc);
                            (_, Acc) ->
                                Acc
                        end, -1, Effects),
            true;
        _ ->
            true
    catch
        Err ->
            ct:pal("Commands: ~p~nConf~p~n", [Commands, Conf]),
            ct:pal("Err: ~p~n", [Err]),
            false
    end.

%% single active consumer ordering invariant:
%% only redelivered messages can go backwards
validate_msg_order(_, [], S) ->
    S;
validate_msg_order(Cid, [{_, {H, Num}} | Rem], PrevMax) ->
    Redelivered = maps:is_key(delivery_count, H),
    case undefined of
        _ when Num == PrevMax + 1 ->
            %% forwards case
            validate_msg_order(Cid, Rem, Num);
        _ when Redelivered andalso Num =< PrevMax ->
            %% the seq is lower but this is a redelivery
            %% when the consumer changed and the next messages has been redelivered
            %% we may go backwards but keep the highest seen
            validate_msg_order(Cid, Rem, PrevMax);
        _ ->
            ct:pal("out of order ~w Prev ~w Curr ~w Redel ~w",
                   [Cid, PrevMax, Num, Redelivered]),
            throw({outoforder, Cid, PrevMax, Num})
    end.




dump_generated(Conf, Commands) ->
    ct:pal("Commands: ~p~nConf~p~n", [Commands, Conf]),
    true.

snapshots_prop(Conf, Commands) ->
    try run_snapshot_test(Conf, Commands) of
        _ -> true
    catch
        Err ->
            ct:pal("Commands: ~p~nConf~p~n", [Commands, Conf]),
            ct:pal("Err: ~p~n", [Err]),
            false
    end.

log_gen(Size) ->
    log_gen(Size, binary()).

log_gen(Size, _Body) ->
    Nodes = [node(),
             fakenode@fake,
             fakenode@fake2
            ],
    ?LET(EPids, vector(2, pid_gen(Nodes)),
         ?LET(CPids, vector(2, pid_gen(Nodes)),
              resize(Size,
                     list(
                       frequency(
                         [{20, enqueue_gen(oneof(EPids))},
                          {40, {input_event,
                                frequency([{10, settle},
                                           {2, return},
                                           {1, discard},
                                           {1, requeue}])}},
                          {2, checkout_gen(oneof(CPids))},
                          {1, checkout_cancel_gen(oneof(CPids))},
                          {1, down_gen(oneof(EPids ++ CPids))},
                          {1, nodeup_gen(Nodes)},
                          {1, purge}
                         ]))))).

log_gen_ordered(Size) ->
    Nodes = [node(),
             fakenode@fake,
             fakenode@fake2
            ],
    ?LET(EPids, vector(1, pid_gen(Nodes)),
         ?LET(CPids, vector(5, pid_gen(Nodes)),
              resize(Size,
                     list(
                       frequency(
                         [{20, enqueue_gen(oneof(EPids), 10, 0)},
                          {40, {input_event,
                                frequency([{10, settle},
                                           {2, return},
                                           {1, discard},
                                           {1, requeue}])}},
                          {2, checkout_gen(oneof(CPids))},
                          {1, checkout_cancel_gen(oneof(CPids))},
                          {1, down_gen(oneof(EPids ++ CPids))},
                          {1, nodeup_gen(Nodes)}
                         ]))))).

monotonic_gen() ->
    ?LET(_, integer(), erlang:unique_integer([positive, monotonic])).

pid_gen(Nodes) ->
    ?LET(Node, oneof(Nodes),
         test_util:fake_pid(atom_to_binary(Node, utf8))).

down_gen(Pid) ->
    ?LET(E, {down, Pid, oneof([noconnection, noproc])}, E).

nodeup_gen(Nodes) ->
    {nodeup, oneof(Nodes)}.

enqueue_gen(Pid) ->
    enqueue_gen(Pid, 10, 1).

enqueue_gen(Pid, Enq, Del) ->
    ?LET(E, {enqueue, Pid,
             frequency([{Enq, enqueue},
                        {Del, delay}]),
             binary()}, E).

checkout_cancel_gen(Pid) ->
    {checkout, Pid, cancel}.

checkout_gen(Pid) ->
    %% pid, tag, prefetch
    ?LET(C, {checkout, {binary(), Pid}, choose(1, 100)}, C).


-record(t, {state = rabbit_fifo:init(#{name => proper,
                                       queue_resource => blah,
                                       release_cursor_interval => 1})
                :: rabbit_fifo:state(),
            index = 1 :: non_neg_integer(), %% raft index
            enqueuers = #{} :: #{pid() => term()},
            consumers = #{} :: #{{binary(), pid()} => term()},
            effects = queue:new() :: queue:queue(),
            %% to transform the body
            enq_body_fun = {0, fun ra_lib:id/1},
            log = [] :: list(),
            down = #{} :: #{pid() => noproc | noconnection}
           }).

expand(Ops) ->
    expand(Ops, {undefined, fun ra_lib:id/1}).

expand(Ops, EnqFun) ->
    %% execute each command against a rabbit_fifo state and capture all relevant
    %% effects
    T = #t{enq_body_fun = EnqFun},
    #t{effects = Effs} = T1 = lists:foldl(fun handle_op/2, T, Ops),
    %% process the remaining effect
    #t{log = Log} = lists:foldl(fun do_apply/2,
                                T1#t{effects = queue:new()},
                                queue:to_list(Effs)),

    lists:reverse(Log).


handle_op({enqueue, Pid, When, Data},
          #t{enqueuers = Enqs0,
             enq_body_fun = {EnqSt0, Fun},
             down = Down,
             effects = Effs} = T) ->
    case Down of
        #{Pid := noproc} ->
            %% if it's a noproc then it cannot exist - can it?
            %% drop operation
            T;
        _ ->
            Enqs = maps:update_with(Pid, fun (Seq) -> Seq + 1 end, 1, Enqs0),
            MsgSeq = maps:get(Pid, Enqs),
            {EnqSt, Msg} = Fun({EnqSt0, Data}),
            Cmd = rabbit_fifo:make_enqueue(Pid, MsgSeq, Msg),
            case When of
                enqueue ->
                    do_apply(Cmd, T#t{enqueuers = Enqs,
                                      enq_body_fun = {EnqSt, Fun}});
                delay ->
                    %% just put the command on the effects queue
                    T#t{effects = queue:in(Cmd, Effs),
                        enqueuers = Enqs,
                        enq_body_fun = {EnqSt, Fun}}
            end
    end;
handle_op({checkout, Pid, cancel}, #t{consumers  = Cons0} = T) ->
    case maps:keys(
           maps:filter(fun ({_, P}, _) when P == Pid -> true;
                           (_, _) -> false
                       end, Cons0)) of
        [CId | _] ->
            Cons = maps:remove(CId, Cons0),
            Cmd = rabbit_fifo:make_checkout(CId, cancel, #{}),
            do_apply(Cmd, T#t{consumers = Cons});
        _ ->
            T
    end;
handle_op({checkout, CId, Prefetch}, #t{consumers  = Cons0} = T) ->
    case Cons0 of
        #{CId := _} ->
            %% ignore if it already exists
            T;
        _ ->
            Cons = maps:put(CId, ok,  Cons0),
            Cmd = rabbit_fifo:make_checkout(CId,
                                            {auto, Prefetch, simple_prefetch},
                                            #{ack => true,
                                              prefetch => Prefetch,
                                              username => <<"user">>,
                                              args => []}),

            do_apply(Cmd, T#t{consumers = Cons})
    end;
handle_op({down, Pid, Reason} = Cmd, #t{down = Down} = T) ->
    case Down of
        #{Pid := noproc} ->
            %% it it permanently down, cannot upgrade
            T;
        _ ->
            %% it is either not down or down with noconnection
            do_apply(Cmd, T#t{down = maps:put(Pid, Reason, Down)})
    end;
handle_op({nodeup, _} = Cmd, T) ->
    do_apply(Cmd, T);
handle_op({input_event, requeue}, #t{effects = Effs} = T) ->
    %% this simulates certain settlements arriving out of order
    case queue:out(Effs) of
        {{value, Cmd}, Q} ->
            T#t{effects = queue:in(Cmd, Q)};
        _ ->
            T
    end;
handle_op({input_event, Settlement}, #t{effects = Effs,
                                        down = Down} = T) ->
    case queue:out(Effs) of
        {{value, {settle, MsgIds, CId}}, Q} ->
            Cmd = case Settlement of
                      settle -> rabbit_fifo:make_settle(CId, MsgIds);
                      return -> rabbit_fifo:make_return(CId, MsgIds);
                      discard -> rabbit_fifo:make_discard(CId, MsgIds)
                  end,
            do_apply(Cmd, T#t{effects = Q});
        {{value, {enqueue, Pid, _, _} = Cmd}, Q} ->
            case maps:is_key(Pid, Down) of
                true ->
                    %% enqueues cannot arrive after down for the same process
                    %% drop message
                    T#t{effects = Q};
                false ->
                    do_apply(Cmd, T#t{effects = Q})
            end;
        _ ->
            T
    end;
handle_op(purge, T) ->
    do_apply(rabbit_fifo:make_purge(), T).


do_apply(Cmd, #t{effects = Effs,
                 index = Index, state = S0,
                 down = Down,
                 log = Log} = T) ->
    case Cmd of
        {enqueue, Pid, _, _} when is_map_key(Pid, Down) ->
            %% down
            T;
        _ ->
            {St, Effects} = case rabbit_fifo:apply(#{index => Index}, Cmd, S0) of
                                {S, _, E} when is_list(E) ->
                                    {S, E};
                                {S, _, E} ->
                                    {S, [E]};
                                {S, _} ->
                                    {S, []}
                            end,

            T#t{state = St,
                index = Index + 1,
                effects = enq_effs(Effects, Effs),
                log = [Cmd | Log]}
    end.

enq_effs([], Q) -> Q;
enq_effs([{send_msg, P, {delivery, CTag, Msgs}, ra_event} | Rem], Q) ->
    MsgIds = [I || {I, _} <- Msgs],
    %% always make settle commands by default
    %% they can be changed depending on the input event later
    Cmd = rabbit_fifo:make_settle({CTag, P}, MsgIds),
    enq_effs(Rem, queue:in(Cmd, Q));
enq_effs([_ | Rem], Q) ->
    enq_effs(Rem, Q).


%% Utility
run_proper(Fun, Args, NumTests) ->
    ?assertEqual(
       true,
       proper:counterexample(
         erlang:apply(Fun, Args),
         [{numtests, NumTests},
          {on_output, fun(".", _) -> ok; % don't print the '.'s on new lines
                         (F, A) -> ct:pal(?LOW_IMPORTANCE, F, A)
                      end}])).

run_snapshot_test(Conf, Commands) ->
    %% create every incremental permutation of the commands lists
    %% and run the snapshot tests against that
    [begin
         % ?debugFmt("~w running command to ~w~n", [?FUNCTION_NAME, lists:last(C)]),
         run_snapshot_test0(Conf, C)
     end || C <- prefixes(Commands, 1, [])].

run_snapshot_test0(Conf, Commands) ->
    Indexes = lists:seq(1, length(Commands)),
    Entries = lists:zip(Indexes, Commands),
    {State0, Effects} = run_log(test_init(Conf), Entries),
    State = rabbit_fifo:normalize(State0),

    [begin
         % ct:pal("release_cursor: ~b~n", [SnapIdx]),
         %% drop all entries below and including the snapshot
         Filtered = lists:dropwhile(fun({X, _}) when X =< SnapIdx -> true;
                                       (_) -> false
                                    end, Entries),
         {S0, _} = run_log(SnapState, Filtered),
         S = rabbit_fifo:normalize(S0),
         % assert log can be restored from any release cursor index
         case S of
             State -> ok;
             _ ->
                 ct:pal("Snapshot tests failed run log:~n"
                        "~p~n from ~n~p~n Entries~n~p~n"
                        "Config: ~p~n",
                        [Filtered, SnapState, Entries, Conf]),
                 ct:pal("Expected~n~p~nGot:~n~p", [State, S]),
                 ?assertEqual(State, S)
         end
     end || {release_cursor, SnapIdx, SnapState} <- Effects],
    ok.

%% transforms [1,2,3] into [[1,2,3], [1,2], [1]]
prefixes(Source, N, Acc) when N > length(Source) ->
    lists:reverse(Acc);
prefixes(Source, N, Acc) ->
    {X, _} = lists:split(N, Source),
    prefixes(Source, N+1, [X | Acc]).

run_log(InitState, Entries) ->
    run_log(InitState, Entries, fun(_) -> true end).

run_log(InitState, Entries, InvariantFun) ->
    Invariant = fun(E, S) ->
                       case InvariantFun(S) of
                           true -> ok;
                           false ->
                               throw({invariant, E, S})
                       end
                end,

    lists:foldl(fun ({Idx, E}, {Acc0, Efx0}) ->
                        case rabbit_fifo:apply(meta(Idx), E, Acc0) of
                            {Acc, _, Efx} when is_list(Efx) ->
                                Invariant(E, Acc),
                                {Acc, Efx0 ++ Efx};
                            {Acc, _, Efx}  ->
                                Invariant(E, Acc),
                                {Acc, Efx0 ++ [Efx]};
                            {Acc, _}  ->
                                Invariant(E, Acc),
                                {Acc, Efx0}
                        end
                end, {InitState, []}, Entries).

test_init(Conf) ->
    Default = #{queue_resource => blah,
                release_cursor_interval => 0,
                metrics_handler => {?MODULE, metrics_handler, []}},
    rabbit_fifo:init(maps:merge(Default, Conf)).

meta(Idx) ->
    #{index => Idx, term => 1}.

make_checkout(Cid, Spec) ->
    rabbit_fifo:make_checkout(Cid, Spec, #{}).

make_enqueue(Pid, Seq, Msg) ->
    rabbit_fifo:make_enqueue(Pid, Seq, Msg).

make_settle(Cid, MsgIds) ->
    rabbit_fifo:make_settle(Cid, MsgIds).

make_return(Cid, MsgIds) ->
    rabbit_fifo:make_return(Cid, MsgIds).
