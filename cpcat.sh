#!/bin/sh

#
# cpcat - a simple package management, file backup and synchronization script
#
# @author       Mort Yao
# @version      2012-03-04
#
VERSION=0.8.2

TAR=tar
LOGPATH="/var/log/cpcat/packages"

exec_help_pack() {
    echo -e "cpcat pack [DIR_PATH]..."
    echo -e "cpcat pack [CONFIG_FILE]..."
}

exec_help_unpack() {
    echo -e "cpcat unpack [ARCHIVE_FILE]"
}

exec_help_install() {
    echo -e "cpcat install [ARCHIVE_FILE]"
}

exec_help_uninstall() {
    echo -e "cpcat uninstall [PACKAGE_NAME]"
    echo -e "cpcat remove [PACKAGE_NAME]"
}

exec_help_list() {
    echo -e "cpcat list"
}

exec_help_info() {
    echo -e "cpcat info [PACKAGE_NAME]"
}

exec_help_whose() {
    echo -e "cpcat whose [FILE_PATH]"
}

exec_help_sync() {
    echo -e "cpcat sync [SOURCE_DIR_PATH] [TARGET1_DIR_PATH]..."
}

exec_help_help() {
    echo -e "cpcat help"
}

exec_help_version() {
    echo -e "cpcat version"
}

exec_help() {
    echo "Usage:"
    exec_help_pack
    exec_help_unpack
    exec_help_install
    exec_help_uninstall
    exec_help_list
    exec_help_info
    exec_help_whose
    exec_help_sync
    exec_help_help
    exec_help_version
    exit 0
}

exec_version() {
    echo "cpcat: version $VERSION"
    exit 0
}

exec_pack_core() {
    PKGFILENAME=$PWD/$NAME
    for TMPSTR in $VERSION $BUILD $SYS_NAME $SYS_VERSION $SYS_BUILD $STATUS $COMP_CLASS $COMP_VERSION; do
        if [ $TMPSTR ]; then
            PKGFILENAME=$PKGFILENAME'-'$TMPSTR
        fi
    done
    if [ -z $FORMAT ]; then
        FORMAT=txz
    fi
    PKGFILENAME=$PKGFILENAME~`date +%Y%m%d%H%M%S`.$FORMAT
    
    case $FORMAT in
        'tgz' | 'tar.gz' )
            ARCHIVEFILTER="--gzip"
            ;;
        'tbz' | 'tar.bz2' )
            ARCHIVEFILTER="--bzip2"
            ;;
        'tlz' | 'tar.lzma' )
            ARCHIVEFILTER="--lzma"
            ;;
        'txz' | 'tar.xz' )
            ARCHIVEFILTER="--xz"
            ;;
        * )
            ARCHIVEFILTER=
            echo "    cpcat: unknown compression type: $FORMAT"
            continue
            ;;
    esac
    
    (cd $TARGET; $TAR cvf $PKGFILENAME $FILES $ARCHIVEFILTER --exclude=$PKGFILENAME)
    
    if [ $? -ne 0 ]; then
        echo "    cpcat: compression failed."
        return 1
    else
        return 0
    fi
}

exec_pack() {
    if [ $# -eq 0 ]; then
        echo "Usage:"
        exec_help_unpack
        exit 0
    else
        COUNTER=0
        for TARGET; do
            NAME=; VERSION=; BUILD=;
            SYS_NAME=; SYS_VERSION=; SYS_BUILD=;
            STATUS=; COMP_CLASS=; COMP_VERSION=;
            FORMAT=; DESC=; FILES=;
            
            TARGET=${TARGET%/}
            if [ -d $TARGET ]; then
                if [ -r "$TARGET/.cpcat" ]; then
                    echo "cpcat: reading $TARGET/.cpcat ..."
                    . ./$TARGET/.cpcat
                    if [ $? -ne 0 ]; then
                        echo "cpcat: $TARGET/.cpcat: an error occured in target file."
                    fi
                else
                    echo "cpcat: $TARGET/.cpcat not found. Using default settings."
                fi
                
                if [[ -z $NAME ]]; then
                    echo "cpcat: NAME not specified. Using the directory name."
                    NAME=${TARGET##*/}
                fi
                if [[ -z $FILES ]]; then
                    echo "cpcat: FILES not specified. Packing all files under the directory."
                    FILES="."
                fi
                
                exec_pack_core
                
                if [ $? -ne 0 ]; then
                    echo "cpcat: $TARGET: target failed."
                    continue
                else
                    echo "cpcat: $TARGET: target succeeded."
                    (( COUNTER = COUNTER + 1 ))
                fi
                
            elif [ -r $TARGET ]; then
                if [ -r "$TARGET" ]; then
                    echo "cpcat: reading $TARGET ..."
                    . ./$TARGET
                    if [ $? -ne 0 ]; then
                        echo "cpcat: $TARGET: an error occured in target file."
                    fi
                else
                    echo "cpcat: $TARGET: target not found."
                    continue
                fi
                
                if [[ -z $NAME ]]; then
                    echo "cpcat: NAME not specified"
                    continue
                fi
                if [[ -z $FILES ]]; then
                    echo "cpcat: FILES not specified."
                    continue
                fi
                
                exec_pack_core
                
                if [ $? -ne 0 ]; then
                    echo "cpcat: $TARGET: target failed."
                    continue
                else
                    echo "cpcat: $TARGET: target succeeded."
                    (( COUNTER = COUNTER + 1 ))
                fi
                
            else
                echo "cpcat: $TARGET: target not found."
                continue
            fi
        done
        
        echo "cpcat: $# target(s) processed, $COUNTER package(s) successfully made."
        if [ $COUNTER -ne 0 ]; then
            exit 0
        else
            exit 1
        fi
    fi
}

exec_unpack() {
    if [ $# -eq 0 ]; then
        echo "Usage:"
        exec_help_unpack
        exit 0
    else
        COUNTER=0
        for TARGET; do
            NAME=; VERSION=; BUILD=;
            SYS_NAME=; SYS_VERSION=; SYS_BUILD=;
            STATUS=; COMP_CLASS=; COMP_VERSION=;
            FORMAT=; DESC=; FILES=;
            
            if [ -r $TARGET ]; then
                case ${TARGET##*.} in
                    'tgz' | 'gz' )
                        ARCHIVEFILTER="--gzip"
                        ;;
                    'tbz' | 'bz2' )
                        ARCHIVEFILTER="--bzip2"
                        ;;
                    'tlz' | 'lzma' )
                        ARCHIVEFILTER="--lzma"
                        ;;
                    'txz' | 'xz' )
                        ARCHIVEFILTER="--xz"
                        ;;
                    * )
                        ARCHIVEFILTER=
                        echo "    cpcat: unknown compression type: ${TARGET##*.}"
                        continue
                        ;;
                esac
                
                $TAR xvf $TARGET -C . $ARCHIVEFILTER
                
                if [ $? -ne 0 ]; then
                    echo "cpcat: $TARGET: target failed."
                    continue
                else
                    echo "cpcat: $TARGET: target succeeded."
                    (( COUNTER = COUNTER + 1 ))
                fi
            else
                echo "cpcat: $TARGET: target not found."
                continue
            fi
        done
        
        echo "cpcat: $# target(s) processed, $COUNTER package(s) successfully unpacked."
        if [ $COUNTER -ne 0 ]; then
            exit 0
        else
            exit 1
        fi
    fi
}

exec_install() {
    if [ $# -eq 0 ]; then
        echo "Usage:"
        exec_help_install
        exit 0
    else
        COUNTER=0
        for TARGET; do
            NAME=; VERSION=; BUILD=;
            SYS_NAME=; SYS_VERSION=; SYS_BUILD=;
            STATUS=; COMP_CLASS=; COMP_VERSION=;
            FORMAT=; DESC=; FILES=;
            
            if [ -r $TARGET ]; then
                case ${TARGET##*.} in
                    'tgz' | 'gz' )
                        ARCHIVEFILTER="--gzip"
                        ;;
                    'tbz' | 'bz2' )
                        ARCHIVEFILTER="--bzip2"
                        ;;
                    'tlz' | 'lzma' )
                        ARCHIVEFILTER="--lzma"
                        ;;
                    'txz' | 'xz' )
                        ARCHIVEFILTER="--xz"
                        ;;
                    * )
                        ARCHIVEFILTER=
                        echo "    cpcat: unknown compression type: ${TARGET##*.}"
                        continue
                        ;;
                esac
                
                sudo $TAR xvf $TARGET -C / $ARCHIVEFILTER
                
                if [ $? -ne 0 ]; then
                    echo "cpcat: $TARGET: target failed."
                    continue
                else
                    if [ -r "/.cpcat_inst" ]; then
                        sudo . /.cpcat_inst
                    fi
                    
                    . /.cpcat
                    sudo mkdir -p $LOGPATH
                    sudo mv -f /.cpcat $LOGPATH/$NAME
                    sudo mv -f /.cpcat_inst $LOGPATH/$NAME.inst 2>/dev/null
                    sudo mv -f /.cpcat_uninst $LOGPATH/$NAME.uninst 2>/dev/null
                    
                    echo "cpcat: $TARGET: target succeeded."
                    (( COUNTER = COUNTER + 1 ))
                fi
            else
                echo "cpcat: $TARGET: target not found."
                continue
            fi
        done
        
        echo "cpcat: $# target(s) processed, $COUNTER package(s) successfully installed."
        if [ $COUNTER -ne 0 ]; then
            exit 0
        else
            exit 1
        fi
    fi
}

exec_uninstall() {
    if [ $# -eq 0 ]; then
        echo "Usage:"
        exec_help_uninstall
        exit 0
    else
        COUNTER=0
        for TARGET; do
            NAME=; VERSION=; BUILD=;
            SYS_NAME=; SYS_VERSION=; SYS_BUILD=;
            STATUS=; COMP_CLASS=; COMP_VERSION=;
            FORMAT=; DESC=; FILES=;
            
            if [ -r $LOGPATH/$TARGET ]; then
                . $LOGPATH/$TARGET
                (cd /; sudo rm -fr $FILES 2>/dev/null)
                
                if [ -r "$LOGPATH/$TARGET.uninst" ]; then
                    sudo . $LOGPATH/$TARGET.uninst
                fi
                
                sudo rm -f $LOGPATH/$TARGET
                sudo rm -f $LOGPATH/$TARGET.inst 2>/dev/null
                sudo rm -f $LOGPATH/$TARGET.uninst 2>/dev/null
                
                echo "cpcat: $TARGET: target succeeded."
                (( COUNTER = COUNTER + 1 ))
            else
                echo "cpcat: $TARGET: target not found."
                continue
            fi
        done
        
        echo "cpcat: $# target(s) processed, $COUNTER package(s) successfully uninstalled."
        if [ $COUNTER -ne 0 ]; then
            exit 0
        else
            exit 1
        fi
    fi
}

exec_list() {
    PKG_NAMES=(`ls $LOGPATH 2>/dev/null`)
    for PKG_NAME in ${PKG_NAMES[*]}; do
        NAME=; VERSION=; BUILD=;
        . $LOGPATH/$PKG_NAME
        echo -n $NAME $VERSION
        if [ $BUILD ]; then
            echo -n '-'$BUILD
        fi
        echo
    done
    
    exit 0
}

exec_info() {
    if [ $# -eq 0 ]; then
        echo "Usage:"
        exec_help_info
        exit 0
    else
        COUNTER=0
        for TARGET; do
            if [ ! -r $LOGPATH/$TARGET ]; then
                echo "cpcat: $TARGET: package not found."
                continue
            fi
            NAME=; VERSION=; BUILD=;
            . $LOGPATH/$TARGET
            echo "Package Name:   "$NAME
            echo "Version:        "$VERSION
            echo "Build ID:       "$BUILD
            echo -e $DESC
            echo
        done
        exit 0
    fi
}

exec_whose() {
    if [ $# -eq 0 ]; then
        echo "Usage:"
        exec_help_whose
        exit 0
    else
        COUNTER=0
        for TARGET; do
            if [ ! -f $TARGET ]; then
                echo "cpcat: $TARGET: file not exist."
                continue
            fi

            PKG_NAMES=(`fgrep -l "${TARGET#/} " $LOGPATH/* 2>/dev/null`)
            PKG_NAMES=(${PKG_NAMES[*]##*/})
            echo "cpcat: $TARGET: belongs to: ${PKG_NAMES[*]}"
        done
        exit 0
    fi
}

exec_sync() {
    if [ $# -ne 2 ]; then
        echo "Usage:"
        exec_help_sync
        exit 0
    else
        SOURCE=$1
        NAME=${SOURCE##*/}
        if [ ! -r $SOURCE ]; then
            echo "cpcat: $SOURCE: sync source not found."
            exit 1
        fi
        
        shift
        IS_VERBOSE='-v'
        for TARGET do
            TARGET=${TARGET%/}
            if [ -n "$TARGET" ]; then
                echo "cpcat: synchronizing from $SOURCE to $TARGET ..."
                if [ -e "$TARGET/$NAME" ]; then
                    SBID=$RANDOM
                    while [ -e "$TARGET/$NAME~$SBID" ]; do
                        SBID=$RANDOM
                    done
                    mv $IS_VERBOSE -f $TARGET/$NAME $TARGET/$NAME~$SBID
                    cp $IS_VERBOSE -fr $SOURCE $TARGET/$NAME
                    if [ $? -eq 0 ]; then
                        rm $IS_VERBOSE -fr $TARGET/$NAME~$SBID
                        echo "cpcat: synchronization succeeded."
                    else
                        echo "cpcat: synchronization from $SOURCE to $TARGET failed."
                        continue
                    fi
                else
                    mkdir $IS_VERBOSE -p $TARGET
                    cp $IS_VERBOSE -fr $SOURCE $TARGET/$NAME
                    if [ $? -eq 0 ]; then
                        echo "cpcat: synchronization succeeded."
                    else
                        echo "cpcat: synchronization from $SOURCE to $TARGET failed."
                        continue
                    fi
                fi
            else
                echo "cpcat: synchronization from $SOURCE to $TARGET failed."
                continue
            fi
        done
        
        exit 0
    fi
}



if [ $# -eq 0 ]; then
    exec_help
fi

case $1 in
    'version' | '--version' | '-V' )
        exec_version $*
        ;;
    'help' | '--help' | '-h' )
        exec_help $*
        ;;
    'pack' )
        shift
        exec_pack $*
        ;;
    'unpack' )
        shift
        exec_unpack $*
        ;;
    'install' )
        shift
        exec_install $*
        ;;
    'uninstall' | 'remove' )
        shift
        exec_uninstall $*
        ;;
    'list' )
        exec_list $*
        ;;
    'info' )
        shift
        exec_info $*
        ;;
    'whose' )
        shift
        exec_whose $*
        ;;
    'sync' )
        shift
        exec_sync $*
        ;;
    * )
        echo "cpcat: invalid option -- $1. Try 'cpcat --help' for more information."
        ;;
esac
