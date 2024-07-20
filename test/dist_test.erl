%%% -------------------------------------------------------------------
%%% @author  : Joq Erlang
%%% @doc: : 
%%% Created :
%%% Node end point  
%%% Creates and deletes Pods
%%% 
%%% API-kube: Interface 
%%% Pod consits beams from all services, app and app and sup erl.
%%% The setup of envs is
%%% -------------------------------------------------------------------
-module(dist_test).      
 
-export([start/0]).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-define(MainLogDir,"logs").
-define(LocalLogDir,"log.logs").
-define(LogFile,"test_logfile").
-define(MaxNumFiles,10).
-define(MaxNumBytes,100000).

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    
    ok=setup(),
    ok=normal_test(),
  %  ok=dist_test:start(),
 
    io:format("Test OK !!! ~p~n",[?MODULE]),
   % timer:sleep(1000),
   % init:stop(),
    ok.


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
normal_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    [N0,N1,N2]=test_nodes:get_nodes(),
    ok=rpc:call(N0,kvs,create,[key1,value1],5000),
    
    {ok,[{key1,value1}]}=rpc:call(N0,kvs,get_all,[],5000),
    {ok,[{key1,value1}]}=rpc:call(N1,kvs,get_all,[],5000),
    {ok,[{key1,value1}]}=rpc:call(N2,kvs,get_all,[],5000),
    {ok,value1}=kvs:read(key1),
    {error,["Doesnt exists Key ",glurk,lib_kvs,_]}=kvs:read(glurk),
    
    ok=kvs:update(key1,value11),
    {ok,value11}=kvs:read(key1),
    {error,["Doesn't exists",glurk,lib_kvs,_]}=kvs:update(glurk,value11),
    
    ok=kvs:delete(key1),
    {error,["Doesnt exists Key ",key1,lib_kvs,_]}=kvs:read(key1),
    {error,["Doesn't exists",glurk,lib_kvs,_]}=kvs:delete(glurk),
    
  
    ok=kvs:create(key1,value10),
    ok=kvs:create(key2,value20),
   {ok,[{key2,value20},{key1,value10}]}=kvs:get_all(),

    ok.
    


%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
   
    file:del_dir_r(?MainLogDir),
    file:make_dir(?MainLogDir),
  
    NodeNames=test_nodes:get_nodenames(),
    [{ok,N0},{ok,N1},{ok,N2}]=[test_nodes:start_slave(Nm)||Nm<-NodeNames],
    
    {ok,HostName}=net:gethostname(),
    NodeNodeLogDirs=[{list_to_atom(NodeName++"@"++HostName),filename:join(?MainLogDir,NodeName)}||NodeName<-NodeNames],
    Nodes=test_nodes:get_nodes(),
    [rpc:call(N1,net_adm,ping,[N2],5000)||N1<-Nodes,
					  N2<-Nodes],
    [rpc:call(N,code,add_patha,["ebin"],5000)||N<-Nodes],
    [rpc:call(N,code,add_patha,["test_ebin"],5000)||N<-Nodes],
    
    start_kvs(NodeNodeLogDirs),
  %  start_kvs(NodeNodeLogDirs),
   % [{ok,_},{ok,_},{ok,_}]=[rpc:call(N,log,start_link,[],10000)||N<-Nodes],
%    [rpc:call(N,log,create_logger,[NodeNodeLogDir,?LocalLogDir,?LogFile,?MaxNumFiles,?MaxNumBytes],5000)||{N,NodeNodeLogDir}<-NodeNodeLogDirs],
  

%    [rpc:call(N,rd,start_link,[],10000)||N<-Nodes],
  %  [pong,pong,pong]=[rpc:call(N,rd,ping,[],10000)||N<-Nodes],
    

%    [rpc:call(N,kvs,start_link,[],10000)||N<-Nodes],
 %   [pong,pong,pong]=[rpc:call(N,kvs,ping,[],10000)||N<-Nodes],
  %  [rpc:call(N,mnesia,system_info,[],10000)||N<-Nodes],
    
    

    ok.
start_kvs([])->
    ok;
start_kvs([{Node,NodeNodeLogDir}|T])->
    timer:sleep(1000),
    io:format("Node,NodeNodeLogDir ~p~n",[{Node,NodeNodeLogDir,?MODULE,?FUNCTION_NAME,?LINE}]),
    pong=net_adm:ping(Node),
    ok=rpc:call(Node,application,start,[tests],10000),
    pong=rpc:call(Node,log,ping,[],10000),
    rpc:call(Node,mnesia,system_info,[],10000),
    start_kvs(T).
