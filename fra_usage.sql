accept nrofhours prompt 'Enter number of hours (default: all): ' default '%'

set pages 1000
alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS';

select trunc(COMPLETION_TIME,'HH') Hour,thread# ,
round(sum(BLOCKS*BLOCK_SIZE)/1024/1024/1024) GB,
count(*) Archives from v$archived_log
WHERE COMPLETION_TIME >= (sysdate - interval '&nrofhours' hour)
group by trunc(COMPLETION_TIME,'HH'),thread#  order by 1;

select round(sum(BLOCKS*BLOCK_SIZE)/1024/1024/1024) GB
FROM v$archived_log
WHERE COMPLETION_TIME >= (sysdate - interval '&nrofhours' hour);
