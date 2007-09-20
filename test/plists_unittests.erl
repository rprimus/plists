-module(plists_unittests).
-export([do_tests/0, do_tests/1]).

do_tests() ->
    do_tests(1),
    do_tests(4),
    do_tests({processes, 2}),
    do_tests([4, {processes, 2}]),
    do_tests({timeout, 4000}),
    do_tests({nodes, [{node(), 2}, node()]}),
    do_tests([{nodes, [{node(), 2}, node()]}, {timeout, 4000}, 4]),
    io:format("Ignore the ERROR REPORTs above, they are supposed to be there.~n"),
    io:format("all tests passed :)~n").

do_tests(Malt) ->
    io:format("Testing with malt: ~p~n", [Malt]),
    test_mapreduce(Malt),
    test_all(Malt),
    test_any(Malt),
    test_filter(Malt),
    test_fold(Malt),
    test_foreach(Malt),
    test_map(Malt),
    test_partition(Malt),
    test_sort(Malt),
    test_usort(Malt),
    check_leftovers(),
    do_error_tests(Malt),
    io:format("tests passed :)~n").

do_error_tests(Malt) ->
    {'EXIT', {badarith, _}} = (catch plists:map(fun (X) -> 1/X end, [1,2,3,0,4,5,6], Malt)),
    check_leftovers(),
    if is_list(Malt) ->
	    MaltList = Malt;
       true ->
	    MaltList = [Malt]
    end,
    MaltTimeout0 = [{timeout, 0}|MaltList],
    {'EXIT', timeout} = (catch test_mapreduce(MaltTimeout0)),
    check_leftovers(),
    MaltTimeout40 = [{timeout, 40}|MaltList],
    {'EXIT', timeout} = (catch plists:foreach(fun (_X) -> timer:sleep(1000) end, [1,2,3], MaltTimeout40)),
    check_leftovers(),
    'tests_passed :)'.

check_leftovers() ->
    receive
	{'EXIT', _, _} ->
	    % plists doesn't start processes with spawn_link, so we
	    % know these aren't our fault.
	    check_leftovers();
	M ->
	    io:format("Leftover messages:~n~p~n", [M]),
	    print_leftovers()
    after 0 ->
	    nil
    end.

print_leftovers() ->
    receive
	M ->
	    io:format("~p~n", [M]),
	    print_leftovers()
    after 0 ->
	    exit(leftover_messages)
    end.

test_mapreduce(Malt) ->
    Ans = plists:mapreduce(fun (X) -> lists:map(fun (Y) -> {Y, X} end, lists:seq(1, X-1)) end, [2,3,4,5], Malt),
    % List1 consists of [2,3,4,5]
    List1 = dict:fetch(1, Ans),
    true = lists:all(fun (X) -> lists:member(X, List1) end, [2,3,4,5]),
    false = lists:any(fun (X) -> lists:member(X, List1) end, [1,6]),
    % List3 consists of [4,5]
    List3 = dict:fetch(3, Ans),
    true = lists:all(fun (X) -> lists:member(X, List3) end, [4,5]),
    false = lists:any(fun (X) -> lists:member(X, List3) end, [1,2,3,6]),
    Text = "how many of each letter",
    TextAns = plists:mapreduce(fun (X) -> {X, 1} end, Text, Malt),
    TextAns2 = dict:from_list(lists:map(fun ({X, List}) ->
						{X, lists:sum(List)} end,
			     dict:to_list(TextAns))),
    3 = dict:fetch($e, TextAns2),
    2 = dict:fetch($h, TextAns2),
    1 = dict:fetch($m, TextAns2).
    
test_all(Malt) ->
    true = plists:all(fun even/1, [2,4,6,8], Malt),
    false = plists:all(fun even/1, [2,4,5,8], Malt).

even (X) ->
    case X rem 2 of
	0 ->
	    true;
	1 ->
	    false
    end.

test_any(Malt) ->
    true = plists:any(fun even/1, [1,2,3,4,5], Malt),
    false = plists:any(fun even/1, [1,3,5,7], Malt).

test_filter(Malt) ->
    [2,4,6] = plists:filter(fun even/1, [1,2,3,4,5,6], Malt).

test_fold(Malt) ->
    15 = plists:fold(fun (A, B) -> A+B end, 0, [1,2,3,4,5], Malt),
    Fun = fun (X, A) ->
		  X2 = X*X,
		  if X2>A ->
			  X2;
		     true ->
			  A
		  end
	  end,
    Fuse = fun (A1, A2) when A1 > A2 ->
		   A1;
	       (_A1, A2) ->
		   A2
	   end,
    List = lists:seq(-5, 4),
    25 = plists:fold(Fun, Fuse, -10000, List, Malt),
    25 = plists:fold(Fun, {recursive, Fuse}, -10000, List, Malt).

test_foreach(_Malt) ->
    whatever.

test_map(Malt) ->
    [2,4,6,8,10] = plists:map(fun (X) -> 2*X end, [1,2,3,4,5], Malt).

test_partition(Malt) ->
    {[2,4,6],[1,3,5]} = plists:partition(fun even/1, [1,2,3,4,5,6], Malt).

test_sort(Malt) ->
    Fun = fun (A, B) ->
		  A =< B
	  end,
    [1,2,2,3,4,5,5] = plists:sort(Fun, [2,4,5,1,2,5,3], Malt),
    [1,2,2,3,4,5,5] = plists:sort(Fun, [2,4,5,1,2,5,3], Malt).

test_usort(Malt) ->
    Fun = fun (A, B) ->
		  A =< B
	  end,
    [1,2,3,4,5] = plists:usort(Fun, [2,4,5,1,2,5,3], Malt),
    [1,2,3,4,5] = plists:usort(Fun, [2,4,5,1,2,5,3], Malt).
