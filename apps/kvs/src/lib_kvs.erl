%%%-------------------------------------------------------------------
%%% @author c50 <joq62@c50>
%%% @copyright (C) 2024, c50
%%% @doc
%%%
%%% @end
%%% Created : 15 Apr 2024 by c50 <joq62@c50>
%%%-------------------------------------------------------------------
-module(lib_kvs). 

-include_lib("stdlib/include/qlc.hrl").
-include("kvs.hrl").
%% API
-export([
	 create_table/0,
	 create/2,
	 update/2,
	 read/1,
	 delete/1,
	 get_all/0
	]).

%%%===================================================================
%%% API
%%%===================================================================
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
create(Key,Value) ->
    F = fun() ->
		case mnesia:read({?TABLE,Key}) of
		    []->
			R=#?RECORD{
				   key=Key,
				   value=Value
				  },		
			mnesia:write(R);
		    [KeyValue] ->
			{mnesia:abort({error,["Already exists",KeyValue]})}
		end
	end,
    
    case mnesia:transaction(F) of
	{atomic,ok}->
	    ok;
	Reason ->
	    {error,[Reason,?MODULE,?LINE]}
    end.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
update(Key,NewValue)->
    F = fun() ->
		case mnesia:read({?TABLE,Key}) of
		   []->
			{mnesia:abort(["Doesn't exists",Key])};
		    [_]->
			R=#?RECORD{
				   key=Key,
				   value=NewValue
				  },		
			mnesia:write(R)		     
		end
	end,
    
    case mnesia:transaction(F) of
	{atomic,ok}->
	    ok;
	{aborted,Reason}->
	    {error,lists:append([Reason,[?MODULE,?LINE]])}
    end.   

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
read(Key)->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE),		
		     X#?RECORD.key==Key])),
    case Z of
	[]->
	    {error,["Doesnt exists Key ",Key,?MODULE,?LINE]};
	[R] ->
	    {ok,R#?RECORD.value}
    end.
 
%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
delete(Key) ->
    F = fun() -> 
		case mnesia:read({?TABLE,Key}) of
		   []->
			{mnesia:abort(["Doesn't exists",Key])};
		    [R]->
			mnesia:delete_object(R) 
		end
	end,
    case mnesia:transaction(F) of
	{atomic,ok}->
	    ok;
	{aborted,Reason}->
	    {error,lists:append([Reason,[?MODULE,?LINE]])}
    end.   

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
get_all() ->
    Z=do(qlc:q([X || X <- mnesia:table(?TABLE)])),
    {ok,[{R#?RECORD.key,R#?RECORD.value}||R<-Z]}.

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
create_table()->
    mnesia:create_table(?TABLE, [{attributes, record_info(fields, ?RECORD)},
				 {type,set}
				]),
    mnesia:wait_for_tables([?TABLE], 20000).


%%%===================================================================
%%% Internal functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
do(Q) ->
  F = fun() -> qlc:e(Q) end,
  {atomic, Val} = mnesia:transaction(F),
  Val.
