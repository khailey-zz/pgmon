

UN=kylelf
PW=kylelf
HOST=mymachine.com
SID=kylelf
PORT=5432 

RUN_TIME=43200     # total run time, 12 hours default 43200
RUN_TIME=86400     # total run time, 24 hours default 86400
RUN_TIME=864000    # total run time, 10 days  default 864000
RUN_TIME=-1        #  run continuously

    DEBUG=${DEBUG:-0}            # 1 output debug, 2 include SQLplus output

function usage
{
       echo "Usage: $(basename $0) [username] [password] [host] [sid:$SID] <port=$PORT> <runtime=3600>"
       exit
}

echo "$# =" $#

[[ $# -lt 3 ]] && usage

[[ $# -gt 0 ]] && UN=$1
[[ $# -gt 1 ]] && PW=$2
[[ $# -gt 2 ]] && HOST=$3
[[ $# -gt 3 ]] && SID=$4
[[ $# -gt 4 ]] && PORT=${5:-1521}
[[ $# -gt 5 ]] && RUN_TIME=${6:-3600}


    TARGET=${HOST}:${SID}

function pipesetup {
    MACHINE=`uname -a | awk '{print $1}'`
    case $MACHINE  in
    Linux)
            MKNOD=/bin/mknod
            ;;
    AIX)
            MKNOD=/usr/sbin/mknod
            ;;
    SunOS)
            MKNOD=/etc/mknod
            ;;
    HP-UX)
            MKNOD=mknod
            ;;
    Darwin)
            MKNOD=""
            ;;
    *)
            MKNOD=mknod
            ;;
    esac
    SUF=.dat
    OUTPUT=${LOG}/${TARGET}_connect.log
    CLEANUP=${CLEAN}/${TARGET}_cleanup.sh
    SQLTESTOUT=${TMP}/${TARGET}_collect.out
    OPEN=${TMP}/${TARGET}_collect.open
    PIPE=${TMP}/${TARGET}_collect.pipe
    rm $OPEN $PIPE > /dev/null 2>&1
    touch  $OPEN

    if [ -z "${MKNOD}" ]
    then
      cmd="mkfifo ${PIPE}"
    else
      cmd="$MKNOD $PIPE p"
    fi

    eval $cmd
    tail -f $OPEN >> $PIPE &
    OPENID="$!"
  # run SQLPLUS silent unless DEBUG is 2 or higher
       SILENT=""
    if [[ $DEBUG -lt 2 ]]; then
       SILENT="-s"
    fi
  # SID
    CONNECT="$UN/$PW@(DESCRIPTION= (ADDRESS_LIST= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOST) (PORT=$PORT))) (CONNECT_DATA= (SERVER=DEDICATED) (SID=$SID)))"
  # SERVICE_ID
  # CONNECT="$UN/$PW@(DESCRIPTION= (ADDRESS_LIST= (ADDRESS= (PROTOCOL=TCP) (HOST=$HOST) (PORT=$PORT))) (CONNECT_DATA= (SERVER=DEDICATED) (SERVICE_NAME=$SID)))"
  # cmd="sqlplus $SILENT \"$CONNECT\" < $PIPE &"
    cmd="sqlplus $SILENT \"$CONNECT\" < $PIPE  &"
    cmd="sqlplus $SILENT \"$CONNECT\" < $PIPE > /dev/null &"
    export PGPASSWORD=$PW
    cmd="psql -t -h $HOST  -p $PORT -U $UN  postgres < $PIPE > /dev/null &"
    cmd="psql -t -h $HOST  -p $PORT -U $UN  postgres < $PIPE  &"

    echo "$cmd" >> ${OUTPUT}
    echo $cmd
    eval $cmd
    SQLID="$!"
    echo "kill -9 $SQLID" >> $CLEANUP
    echo "kill -9 $OPENID" >> $CLEANUP
       
}

    # currenlty script collects ASH from v$active_session_history instead of manual

    SLEEP=1

    MON_HOME=${MON_HOME:-"/tmp/MONITOR"} 
    LOG=${LOG:-"$MON_HOME/log"}
    TMP=${TMP:-"/tmp/MONITOR/tmp"}
    CLEAN=${CLEAN:-"$MON_HOME/clean"}
    #[[ ! -d "$MON_HOME" ]] && mkdir $MON_HOME >/dev/null 2>&1
    #[[ ! -d "$LOG" ]] && mkdir $LOG >/dev/null 2>&1
    #[[ ! -d "$TMP" ]] && mkdir $TMP >/dev/null 2>&1
    #[[ ! -d "$CLEAN" ]] && mkdir $CLEAN >/dev/null 2>&1
    [[ ! -d "$MON_HOME" ]] && mkdir $MON_HOME 
    [[ ! -d "$LOG" ]] && mkdir $LOG 
    [[ ! -d "$TMP" ]] && mkdir $TMP 
    [[ ! -d "$CLEAN" ]] && mkdir $CLEAN 
    CURR_DATE=$(date "+%u_%H" ) 
    OUTPUT=${LOG}/${TARGET}_vdbmon.log
    echo "" > $OUTPUT
    SQLTESTOUT=${TMP}/vdbmon_${TARGET}_collect.tmp
    rm $SQLTESTOUT > /dev/null 2>&1
    EXIT=${CLEAN}/${TARGET}_collect.end
    CLEANUP=${CLEAN}/${TARGET}_cleanup.sh
    echo "" > $CLEANUP

    pipesetup

    SUF=.dat
    RUN_TIME=-1        #  run continuously

    trap "echo $CLEANUP;sh $CLEANUP >> $OUTPUT 2>&1 ;exit" 0 3 5 9 15
    echo "echo 'cleanup: exiting ...' " >> $CLEANUP

    type=${type:-"none"}
    if [[ $type == "ash" ]]; then
      COLLECT_LIST=""     
      FAST_SAMPLE="ash"  
      #SLEEP=.5
      SLEEP=1
      ASH_SLEEP=1
    else
      COLLECT_LIST="avgreadsz avgreadms avgwritesz avgwritems throughput aas wts systat ash "     
      COLLECT_LIST=""     
      FAST_SAMPLE="wts"  
      ASH_SLEEP=1
      SLEEP=1
    fi

  # exit if removed
    touch $EXIT

  # printout setup
    for i in 1; do
    echo
    echo "RUN_TIME=$RUN_TIME" 
    echo "COLLECT_LIST=$COLLECT_LIST" 
    echo "FAST_SAMPLE=$FAST_SAMPLE"
    echo "TARGET=$TARGET" 
    echo "DEBUG=$DEBUG" 
    echo
    done 
    #>>$OUTPUT
    #cat $OUTPUT


#   /******************************/
#   *                             *
#   * BEGIN FUNCTION DEFINITIONS  *
#   *                             *
#   /******************************/
#

function logoutput
{
    echo $1
    echo "$1" >> $OUTPUT
}

function debug 
{
if [[ $DEBUG -ge 1 ]]; then
   #   echo "   ** beg debug **"
   var=$*
   nvar=$#
   if test x"$1" = xvar; then
     shift
     let nvar=nvar-1
     while (( $nvar > 0 ))
     do
        eval val='$'{$1} 1>&2
        echo "       :$1:$val:"  1>&2
        shift
        let nvar=nvar-1
     done
   else
     while (( $nvar > 0 ))
     do
        echo "       :$1:"  1>&2
        shift
        let nvar=nvar-1
     done
   fi
   #   echo "   ** end debug **"
fi
}                         

function check_exit 
{
        if [[  ! -f $EXIT ]]; then
           logoutput "exit file removed, exiting at $(date)" 
           #sqlexit
           sleep 1
           cat $CLEANUP >> $OUTPUT
           sh $CLEANUP  > /dev/null 2>&1
           logoutput "check_exit: exiting ..."
           exit
        fi
}

function sqloutput  
{
#       set pagesize 0
#       set feedback off
    cat << EOF >>$PIPE &
       \o $SQLTESTOUT
       select 1 ;
       \o
EOF
}

function testconnect 
{
     CONNECTED=0
     rm $SQLTESTOUT 2>/dev/null
     if [[ $CONNECTED -eq 0 ]]; then
        limit=60
     else
        limit=60
     fi
     sqloutput
     #sleep 1
     count=0
     #if [[ -f $SQLTESTOUT ]]; then
       grep '^ *1'  $SQLTESTOUT >/dev/null  2>&1
       found=$?
     #fi
     debug "before while"
     while [[ $count -lt $limit && $found -gt 0 ]]; do
        debug "found $found"
        debug "loop#   $count limit $limit "

        echo "Trying to connect" >> $OUTPUT
        #sleep $SLEEP
        sleep .5
        count=$(expr $count + 1)
        check_exit

        if [[ -f $SQLTESTOUT ]]; then
          grep '^ *1'  $SQLTESTOUT >/dev/null  2>&1
          found=$?
          debug "sqlplus output file: $SQLTESTOUT, FOUND ! " 
        else 
          debug  "sql output file: $SQLTESTOUT, not found"
        fi
     done
     debug "after while"
     #echo "count# $count limit $limit " 
     if [[ $count -ge $limit ]]; then
       echo "output from sqlplus: " >> $OUTPUT
       if [[ -f $SQLTESTOUT ]]; then
          cat $SQLTESTOUT
          cat $SQLTESTOUT >>$OUTPUT
       else
          logoutput "sqlplus output file: $SQLTESTOUT, not found" 
          logoutput "check user name and password for sqlplus"
          logoutput "try 'export DEBUG=1' and rerun"
       fi
       logoutput "vdbmon.sh : timeout waiting connection to sqlplus" 
       eval $CMD
       cat $CLEANUP >>$OUTPUT
       sh $CLEANUP
       #sqlexit
       logoutput "test_connect: exiting ..."
       exit
       CONNECTED=0
     else
       CONNECTED=1
       touch $OUTPUT
     fi
}

function sqlexit  
{
   for i in 1; do
      echo "exit"
      echo "vdbmon:exit" >> $OUTPUT
      echo ""
      echo -e "\004"
   done >>$PIPE
}




function wts  
{
     cat << EOF
     \o  ${TMP}/vdbmon_${TARGET}_wts.tmp
     select timeofday(),
          pid,
          usename,
          application_name,
          client_addr,
          wait_event_type,
          wait_event,
          state,
          query  
     from pg_stat_activity where state not like 'idle%'
     and pid !=  pg_backend_pid();
    SELECT
         'total',
         'empty',
         'lsn:durable' ,
         'transactionid' ,
         'tuple' ,
         'lock_manager' ,
         'extend' ,
         'buffer_content' ,
         'buffer_mapping',
         'ProcArrayLock' ;
    SELECT
         count(*) as                                                                  "total   ",
         count(CASE WHEN ash.wait_event is null            THEN  1  ELSE NULL END) AS "empty   ",
         count(CASE WHEN ash.wait_event = 'durable'        THEN  1  ELSE NULL END) AS "lsn:durable",
         count(CASE WHEN ash.wait_event = 'transactionid'  THEN  1  ELSE NULL END) AS "transactionid",
         count(CASE WHEN ash.wait_event = 'tuple'          THEN  1  ELSE NULL END) AS "tuple   ",
         count(CASE WHEN ash.wait_event = 'lock_manager'   THEN  1  ELSE NULL END) AS "lock_manager",
         count(CASE WHEN ash.wait_event = 'extend'         THEN  1  ELSE NULL END) AS "extend  ",
         count(CASE WHEN ash.wait_event = 'buffer_content' THEN  1  ELSE NULL END) AS "buffer_content",
         count(CASE WHEN ash.wait_event = 'buffer_mapping' THEN  1  ELSE NULL END) AS "buffer_mapping",
         count(CASE WHEN ash.wait_event = 'ProcArrayLock'  THEN  1  ELSE NULL END) AS "ProcArrayLock"
     from pg_stat_activity  ash
     where state not like 'idle%'
       and pid !=  pg_backend_pid();
     \o 
EOF
}

# wait times - count, total time
function wts1  
{
     cat << EOF
     \o  ${TMP}/vdbmon_${TARGET}_wts.tmp
          select concat_ws(' , ',timeofday()::text,
                                 pid::text,
                                 usename::text,
                                 application_name::text ,
                                 state::text,
                                 client_addr::text,
                                 wait_event_type::text,
                                 wait_event::text ,
                                 substring(query from 1 for 20)) 
        from pg_stat_activity       
       where state not like 'idle%'  ;
     \o 
EOF
}

function title 
{
  cat << EOF
     select
         'AAS',
         'blks_hit',
         'blks_read',
         'blk_read_time',
         'blk_write_time',
         'tup_returned',
         'tup_fetched',
         'tup_inserted',
         'tup_updated',
         'tup_deleted',
         'n_tup_del',
         'heap_blks_read';
EOF
}

function setup_sql 
{
  cat << EOF
       SET client_min_messages TO WARNING;
     \o  /dev/null
       create temp table vars (nm varchar(30), value bigint);
       insert into vars select 'blks_hit', sum(blks_hit) from  pg_stat_database; 
       insert into vars select 'blks_read', sum(blks_read) from  pg_stat_database; 
       insert into vars select 'blk_read_time', sum(blk_read_time) from  pg_stat_database; 
       insert into vars select 'blk_write_time', sum(blk_read_time) from  pg_stat_database; 
       insert into vars select 'tup_returned', sum(tup_returned) from  pg_stat_database; 
       insert into vars select 'tup_fetched', sum(tup_fetched) from  pg_stat_database; 
       insert into vars select 'tup_inserted', sum(tup_inserted) from  pg_stat_database; 
       insert into vars select 'tup_updated', sum(tup_updated) from  pg_stat_database; 
       insert into vars select 'tup_deleted', sum(tup_deleted) from  pg_stat_database; 
       insert into vars select 'n_tup_del', sum(n_tup_del) from  pg_stat_all_tables; 
       insert into vars select 'heap_blks_read', sum(heap_blks_read) from  pg_statio_all_tables; 
       insert into vars select 'AAS', count(*) from  pg_stat_activity where state not like 'idle%' ;
 ; 
     \o 
EOF
}

#  alter session set sql_trace=false;
#  REM drop sequence orastat;
#  REM create sequence orastat;
#  END FUNCTION DEFINITIONS  
#  BEGIN MAIN LOOP          
  CONNECTED=0
  testconnect
  logoutput "Connected, starting collect at $(date)" 
  #setup
  logoutput "starting stats collecting " 
   #
   # collect stats once a minute
   # every second see if the minute had changed
   # every second check EXIT file exists
   # if EXIT file has been deleted, then exit
   # 
   # change the directory day of the week 1-7
   # day of the week 1-7
   # 
     # variable to track how long collection has run in case script should exit after X amount
     SLEPTED=0
     debug var SLEPTED SAMPLE_RATE
     last_sec=0  
     last_min=0  
     LAST_DATE=$(date "+%u")  
     midnight=1
 
# BEGIN COLLECT LOOP
    if [[ $CONNECTED -eq 1 ]]; then
     check_exit
     setup_sql >>$PIPE
     while [[  ( $SLEPTED -lt $RUN_TIME ||  $RUN_TIME -eq -1 )  && ( -f $EXIT ) ]]; do
      # date = 1-7, day of the week
        CURR_DATE=$(date "+%u")  
        mkdir ${MON_HOME}/${CURR_DATE} >/dev/null 2>&1
        # clean up local, currently done by perfmon.sh
        if [ $LAST_DATE -ne $CURR_DATE ]; then
            midnight=1;
        fi
        curr_sec=$(date "+%H%M%S" | sed -e 's/^0*//' )
        curr_min=$(date "+%H%M" | sed -e 's/^0*//' )  
        # force to 0 incase they are empty after above sed
        curr_sec=$(expr $curr_sec + 0);
        curr_min=$(expr $curr_min + 0);
        
        if [[ $curr_min -gt  $last_min ||  $midnight -eq 1 ]]; then
            ## title >> $PIPE
            debug "COLLECTION: last_min $last_min curr_min $curr_min "
            last_min=$curr_min
            for i in $COLLECT_LIST; do
               ${i} >>$PIPE
            done
        fi
            echo "        -----  "
   
       # this section is only used if collecting ASH
       if [ $curr_sec -gt  $last_sec -o $midnight -eq 1 ]; then
            debug "FAST: last_sec $last_sec curr_sec $curr_sec "
            let last_sec=$curr_sec+$ASH_SLEEP
            for i in $FAST_SAMPLE; do
               ${i} >> $PIPE
            done
            testconnect
            for i in  $FAST_SAMPLE; do
              # prepend each line with the current time 0-235959
              cat ${TMP}/vdbmon_${TARGET}_${i}.tmp  | grep -v '^$' | sed -e 's/XXX.*//' 
              cat ${TMP}/vdbmon_${TARGET}_${i}.tmp  | sed -e "s/^/$last_sec,/" >>${MON_HOME}/${CURR_DATE}/${TARGET}:${i}$SUF
            done
       fi
       midnight=0;
       #sleep $SLEEP 
       sleep 1 
       debug "sleeping 1"
       #debug "sleeping $SAMPLE_RATE"
     done
   fi
 # END COLLECT LOOP
 # CLEANUP
   logoutput "run time expired, exiting at " 
   logdate=`date +'%Y-%m-%d %H:%M:%S'`
   logoutput $logdate  
   # sqlexit
   logoutput "catting cleaning up: $CLEANUP"
   cat $CLEANUP
   logoutput "running cleaning up: $CLEANUP"
   logoutput "exiting ..."
   sh $CLEANUP 
   sleep 1
   logoutput "exited "
