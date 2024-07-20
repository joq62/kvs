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

    [{kvs,Node}|_]=rd:fetch_resources(kvs),
    
    io:format("mnesia system_info ~p~n",[{rpc:call(Node,mnesia,system_info,[],5000),?MODULE,?FUNCTION_NAME,?LINE}]),
    ok=rd:call(kvs,create,[key1,value1],5000),
    {ok,[{key1,value1}]}=rd:call(kvs,get_all,[],5000),
    {ok,value1}=rd:call(kvs,read,[key1],5000),
    {error,["Doesnt exists Key ",glurk,lib_kvs,_]}=rd:call(kvs,read,[glurk],5000),
    
    ok=rd:call(kvs,update,[key1,value11],5000),
    {ok,value11}=rd:call(kvs,read,[key1],5000),
    {error,["Doesn't exists",glurk,lib_kvs,_]}=rd:call(kvs,update,[glurk,value11],5000),
    
    ok=rd:call(kvs,delete,[key1],5000),
    {error,["Doesnt exists Key ",key1,lib_kvs,_]}=rd:call(kvs,read,[key1],5000),
    {error,["Doesn't exists",glurk,lib_kvs,_]}=rd:call(kvs,delete,[glurk],5000),
    
  
    ok=rd:call(kvs,create,[key1,value10],5000),
    ok=rd:call(kvs,create,[key2,value20],5000),
   {ok,[{key2,value20},{key1,value10}]}=rd:call(kvs,get_all,[],5000),

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
    pong=rd:call(kvs,ping,[],6000),
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
    pong=net_adm:ping(?Vm),

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
