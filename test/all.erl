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
-module(all).      
 
-export([start/0]).

-define(TargetDir,"kvs_dir").
-define(Vm,kvs@c50).
-define(TarFile,"kvs.tar.gz").
-define(App,"kvs").
-define(TarSrc,"release"++"/"++?TarFile).
-define(StartCmd,"./"++?TargetDir++"/"++"bin"++"/"++?App).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------
start()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),
    
    ok=setup(),
    ok=load_start_release(),
    ok=rd_test(),
    ok=normal_test(),

 
    io:format("Test OK !!! ~p~n",[?MODULE]),
    timer:sleep(1000),
    init:stop(),
    ok.


%%--------------------------------------------------------------------
%% @doc
%% 
%% @end
%%--------------------------------------------------------------------
normal_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME,?LINE}]),

    io:format("mnesia system_info ~p~n",[{mnesia:system_info(),?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=kvs:create(key1,value1),
    {ok,[{key1,value1}]}=kvs:get_all(),
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

rd_test()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    ok=initial_trade_resources(),
    [{kvs,{kvs,'kvs@c50'}}]=rd:get_all_resources(),
    42=rd:call(kvs,add,[20,22],5000),
    
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------


load_start_release()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),
    
    %% Delete ad_rel dir used for tar, stop Vm
    file:del_dir_r(?TargetDir),
    rpc:call(?Vm,init,stop,[],3000),
    timer:sleep(2000),
    
    %%
    ok=file:make_dir(?TargetDir),
    []=os:cmd("tar -zxf "++?TarSrc++" -C "++?TargetDir),
    
    %%
    []=os:cmd(?StartCmd++" "++"daemon"),
    timer:sleep(3000),
    pong=rpc:call(?Vm,rd,ping,[],5000),
    pong=rpc:call(?Vm,log,ping,[],5000),
    pong=rpc:call(?Vm,kvs,ping,[],5000),
    
    pong=net_adm:ping(?Vm),
    
  


    AllApps=rpc:call(?Vm,application,which_applications,[],6000),
    io:format("AllApps ~p~n",[{AllApps,?MODULE,?LINE,?FUNCTION_NAME}]),
    {ok,Cwd}=rpc:call(?Vm,file,get_cwd,[],6000),
    io:format("Cwd ~p~n",[{Cwd,?MODULE,?LINE,?FUNCTION_NAME}]),
    {ok,Filenames}=rpc:call(?Vm,file,list_dir,[Cwd],6000),
    io:format("Filenames ~p~n",[{Filenames,?MODULE,?LINE,?FUNCTION_NAME}]),
    AbsName=rpc:call(?Vm,code,where_is_file,["python.beam"],6000),
    io:format("AbsName ~p~n",[{AbsName,?MODULE,?LINE,?FUNCTION_NAME}]),
    
    ok.
%% --------------------------------------------------------------------
%% Function: available_hosts()
%% Description: Based on hosts.config file checks which hosts are avaible
%% Returns: List({HostId,Ip,SshPort,Uid,Pwd}
%% --------------------------------------------------------------------

setup()->
    io:format("Start ~p~n",[{?MODULE,?FUNCTION_NAME}]),

    ok=application:start(rd),
    ok=initial_trade_resources(),
    
    ok.


initial_trade_resources()->
    [rd:add_local_resource(ResourceType,Resource)||{ResourceType,Resource}<-[]],
    [rd:add_target_resource_type(TargetType)||TargetType<-[kvs]],
    rd:trade_resources(),
    timer:sleep(3000),
    ok.
