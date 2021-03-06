## Cerberus

Cerberus is an open source, cross platform online game server, developed in C++ and lua, and can run on windows, macos, linux.

## Topology

Main framework:  
![main](pictures/main.png)
In the Server Pack, every server connect to other server directly.  


Server core:  
![core](pictures/core.png)

## Depend

CMake  
Lua 5.3 (build by shared lib)  
Libevent 2  
Lfs  

win64 Libs in [here](https://github.com/mashago/Libs), please copy dir 'lib' and 'include' to `${PROJECT_DIR}`.  
copy libmysql.dll to `${PROJECT_DIR}/bin` when build as debug project in win64.

## Build
in linux or macos  
`cmake .`  
`make`  

in win64  
use cmake-gui

## Run
run on centos or macos  
0. init config
`cd ${PROJECT_DIR}/conf`  
`lua builder.lua`
1. init db  
`cd ${PROJECT_DIR}/conf`  
`mysql -uroot -p < conf/db_login_init.sql`  
`mysql -uroot -p < conf/db_game_init.sql`  
`cd ${PROJECT_DIR}/bin/${PLATFORM}`  
`./sync_db.sh`  
2. startup server  
`./run.sh`  
3. run client  
`./run_client.sh`  

## Test
In client, enter 'help'.



