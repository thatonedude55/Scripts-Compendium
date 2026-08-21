#!/bin/bash

#Todo:
#1. Customise server: Server properties, ops, whitelist etc.
#2. Delete/disable all mods, configs in server. Sync with curseforge. 

set -euo pipefail
VERSION="0.3.0"

MC_PATH="$HOME/Minecraft/Minecraft Server 1.12.2"
JAVA="/usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java"
BACKUP_PATH="$HOME/Minecraft/Minecraft Backup"
SERVER_JAR="forge.jar"
MAX_RAM="9G"
MIN_RAM="2G"

CURSEFORGE_DIR="$HOME/Minecraft/Curseforge/instances"

COMPRESS=true 
#Will add compression of mc world to .tar.gz
#Will add a timestamp feature


BACKUP_MODS=false
BACKUP_WORLD=false
BACKUP_CONFIG=false

PROFILE_SET=false
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

        Default behaviour: Backs up entire server folder

    --import-curseforge [options]
        Imports mods and configs from curseforge instance to server

        Default Behaviour: Imports mods and configs
        

Backup options:

    -n No compression
    
    -w Backup the Minecraft world only
    
    -m Backup the Minecraft mods folder only
    
    -c Backup the Minecraft config folder only

Import options:

    -p Change curseforge profile to import
    
    -m Imports mods only
    
    -c Imports configs only


General options:

    -h --help Display this help message

    -v --version Display program version

Examples:

    mc-server-utils --start-server

    mc-server-utils --stop-server

    mc-server-utils --restart-server

    mc-server-utils --backup-server -n

    mc-server-utils --backup-server -w

    mc-server-utils --backup-server -wmc

    mc-server-utils --import-curseforge -m


    
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
        
	    while kill -0 "$PID" 2>/dev/null; do
		   echo "Waiting for server to stop"
		   sleep 1
	    done
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

Compress_Preparation(){
    
    WORLD_NAME=$(grep '^level-name' "$MC_PATH/server.properties" | cut -d'=' -f2-)
    TIMESTAMP=$(date "+%d-%m-%Y_%H-%M")
    BACKUP_NAME="${WORLD_NAME}, ${TIMESTAMP}.tar.xz"
    
    
}


Backup_Server(){

   	 Compress_Preparation

    
	mkdir -p "$BACKUP_PATH"
	echo "Backup is located at: $BACKUP_PATH"

	 Stop_Server
            
       

         if [[ "$BACKUP_WORLD" == false &&
        	"$BACKUP_MODS" == false &&
        	"$BACKUP_CONFIG" == false ]]; then
        
            echo "No flags specified"
            echo "Backing up entire server directory at: $MC_PATH"

        if [[ "$COMPRESS" == true ]]; then
            tar -cJf "$BACKUP_PATH/ALL_${BACKUP_NAME}" "$MC_PATH"
        
        else
            rsync -avhP "$MC_PATH" "$BACKUP_PATH/"
        fi

	    echo "Backup Completed"
    return 0
    fi  

    if [[ "$BACKUP_WORLD" == true ]]; then
        echo "Backing up world"

        if [[ "$COMPRESS" == true ]]; then
            tar -cJf "$BACKUP_PATH/WORLD_${BACKUP_NAME}" "$MC_PATH/world"
        else
            rsync -avhP "$MC_PATH/world" "$BACKUP_PATH/"
        fi
    echo "World backed up successfully"
    fi

    if [[ "$BACKUP_MODS" == true ]]; then
        echo "Backing up mods"
        if [[ "$COMPRESS" == true ]]; then
            tar -cJf "$BACKUP_PATH/MODS_${BACKUP_NAME}" "$MC_PATH/mods"
        else
            rsync -avhP "$MC_PATH/mods" "$BACKUP_PATH/"
        fi
    echo "Mods backed up successfully"
    fi

    if [[ "$BACKUP_CONFIG" == true ]]; then
        echo "Backing up configs"
        if [[ "$COMPRESS" == true ]]; then
            tar -cJf "$BACKUP_PATH/CONFIG_${BACKUP_NAME}" "$MC_PATH/config"

        else
           rsync -avhP "$MC_PATH/config" "$BACKUP_PATH/"
        fi

    echo "Configs backed up successfully"
    fi
    
}

Set_Curseforge_Profile(){
    echo "Available curseforge profiles"
    ls "$CURSEFORGE_DIR"
        
        read -rp "Please select a profile: " PROFILE 
        
        PROFILE_PATH="$CURSEFORGE_DIR/$PROFILE"    
        
        if [[ ! -d "$PROFILE_PATH" ]]; then
            echo "Profile not found"  
                return 1
        fi
        
        echo "Selected profile: $PROFILE"
        echo "Profile path: $PROFILE_PATH"
        PROFILE_SET=true
    

}


Import_Curseforge(){
    if [[ "$PROFILE_SET" == false ]]; then
        echo "No curseforge profile detected!"
        echo "Use ''./Mc-Server-Utils.sh --import-curseforge -p' to set a profile"
        return 1 
    fi
    
    if [[ "$IMPORT_MODS" == true ]]; then
        echo "Importing mods"
        rsync -avhP "$PROFILE_PATH/mods/" "$MC_PATH/mods/"
        echo "done"

    if [[ "$IMPORT_CONFIG" == true ]]; then
        echo "Importing configs"
        rsync -avhP "$PROFILE_PATH/config/" "$MC_PATH/config/"
        echo "done"
    
    else    
        echo "Importing mods & configs"
        rsync -avhP "$PROFILE_PATH/mods" "$MC_PATH/mods"
        rsync -avhP "$PROFILE_PATH/config/" "$MC_PATH/config/"
        echo "done"
        
    fi
    
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

    --import-curseforge)
        shift
        
        while getopts ":pmc" option; do
            case "$option" in
            p)
                Set_Curseforge_Profile
                ;;
            m)
                IMPORT_MODS=true
                ;;
            c)
                IMPORT_CONFIG=true
                ;;
            \?)
                echo "Unknown flag: -$OPTARG"
                echo "Use --help for more information."
                exit 1
                ;;  
    esac
done
Import_Curseforge
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
