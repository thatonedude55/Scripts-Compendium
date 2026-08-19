#!/bin/bash

#Todo:
#1. Add compression + Timestamping of worlds
#2. Customise server: Server properties, ops, whitelist etc.
#3. Delete/disable all mods, configs in server. Sync with curseforge. 

set -euo pipefail
VERSION="0.1.0"

MC_PATH="$HOME/Minecraft/Minecraft Server 1.12.2"
JAVA="/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java"
BACKUP_PATH="$HOME/Minecraft/Minecraft Backup"
SERVER_JAR="forge.jar"
MAX_RAM="9G"
MIN_RAM="2G"

#COMPRESS=true 
#Will add compression of mc world to .tar.gz
#Will add a timestamp feature


BACKUP_MODS=false
BACKUP_WORLD=false
BACKUP_CONFIG=false


Get_PID(){

PID=$(pgrep -f "java.*-jar.*$SERVER_JAR" | head -n 1 || true)
}

Show_Help(){
    cat << EOF

Minecraft Server Utilities
Usage: 
    Minecraft-Server-Utilities <command> [options]

Commands:
    
    --start-server
        Start the Minecraft server

    --stop-server
        Stop the Minecraft server

    --restart-server
        Restart the Minecraft server

    --backup-server [options]
        Create a backup of the Minecraft server

Backup options:

    -n Disable compression
    
    -w Backup the Minecraft world only
    
    -m Backup the Minecraft mods folder only
    
    -c Backup the Minecraft mods folder only

General options:

    -h --help Display this help message

    -v --version Display program version

Examples:

    mc-server-utils --start-server

    mc-server-utils --stop-server

    mc-server-utils --restart-server

    mc-server-utils --backup-server

    mc-server-utils --backup-server -n

    mc-server-utils --backup-server -w

    mc-server-utils --backup-server -wmc


    
EOF
}

Show_Version(){
    echo "Minecraft-Server-Utilities v$VERSION"
}

Start_Server(){
    cd "$MC_PATH" || return 1
	"$JAVA" -Xmx"$MAX_RAM" -Xms"$MIN_RAM" -jar "$SERVER_JAR" nogui
}

Stop_Server(){
    Get_PID

    if [[ -n $PID ]]; then
        echo "Shutting server down"
	    kill -INT "$PID"
        
        sleep 5 #Change to be more intelligent
	
        echo "Server has stopped"
    else
        echo "Server is not currently running"
    fi


}

Restart_Server(){
	Stop_Server
    
    while kill -0 "$PID" 2>/dev/null; do
        echo "Waiting for server to stop!"
        sleep 2
    done
	
	Start_Server
        
}


Backup_Server(){

    
	mkdir -p "$BACKUP_PATH"
	echo "Backup is located at: $BACKUP_PATH"

    Get_PID
    if [[ -n "$PID" ]]; then
        echo "Stopping server"
	    Stop_Server
            
        while kill -0 "$PID" 2>/dev/null; do
            echo "Waiting for server to stop"
            sleep 2
        done
    fi

    if [[ "$BACKUP_WORLD" == false &&
        "$BACKUP_MODS" == false &&
        "$BACKUP_CONFIG" == false ]]; then
        
        echo "No flags specified"
        echo "Backing up entire server directory at: $MC_PATH"
        
        rsync -avhP "$MC_PATH" "$BACKUP_PATH/"
	    echo "Backup Completed"
        return
    fi

    if [[ "$BACKUP_WORLD" == true ]]; then
        echo "Backing up world"
        rsync -avhP "$MC_PATH/world" "$BACKUP_PATH/"
        echo "World backed up successfully"
    fi

    if [[ "$BACKUP_MODS" == true ]]; then
    echo "Backing up mods"
    rsync -avhP "$MC_PATH/mods" "$BACKUP_PATH/"
    echo "Mods backed up successfully"
    fi

    if [[ "$BACKUP_CONFIG" == true ]]; then
    echo "Backing up configs"
    rsync -avhP "$MC_PATH/config" "$BACKUP_PATH/"
    
    fi
    
}

case "${1:-}" in
    --start-server)
        Start_Server
        ;;
    
    --stop-server)
        Stop_Server
        ;;
    
    --restart-server)
        Restart_Server
        ;;

    --backup-server)
        shift
        
        while getopts ":nwmc" option; do
            case "$option" in
                n)
                    COMPRESS=false
                    ;;

                w)
                    BACKUP_WORLD=true
                    ;;
                c)
                    BACKUP_CONFIG=true
                    ;;

               m)
                    BACKUP_MODS=true
                    ;;
                \?)
                    echo "Unknown backup option: -$OPTARG"
                    echo "Use --help for more information."
                    exit 1
                    ;;
    esac   
done

Backup_Server
;;
         
    

    --help|-h)
        Show_Help
        ;;
    --version|-v)
        Show_Version
        ;;
    *)
        echo "Unknown command, refer to --help for more details"
        exit 1
        ;;
esac

