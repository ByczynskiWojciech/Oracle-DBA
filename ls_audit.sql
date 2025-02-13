set line 220 pagesize 200 verify off

col event_time form A18
col OS_USERNAME form A30
col DBUSERNAME form A30
col OBJECT_NAME form A30
col OBJECT_SCHEMA form A40
col AUDIT_TYPE form a20
col RETURN_CODE form A30

accept nrdays prompt 'Enter number of days to display  (default: 14): ' default '14'
accept objectnamepattern prompt 'Enter object name pattern (default: all): ' default '%'
accept ownerpattern prompt 'Enter owner pattern (default: all): ' default '%'
accept usernamepattern prompt 'Enter username pattern (default: all): ' default '%'
accept audittypepattern prompt 'Enter audit type pattern (default: all): ' default '%'
accept returncodepattern prompt 'Enter return code pattern (default: all): ' default '%'

select to_char(EVENT_TIMESTAMP_UTC,'YYYY-MM-DD HH24:MI') event_time
  ,OS_USERNAME
  ,DBUSERNAME
  ,OBJECT_NAME
  ,OBJECT_SCHEMA
  ,AUDIT_TYPE
  ,RETURN_CODE
from UNIFIED_AUDIT_TRAIL
WHERE   (to_char(CAST(EVENT_TIMESTAMP_UTC AS DATE),'DDMMYYYY') > to_char(sysdate - &nrdays, 'DDMMYYYY')  AND to_char(CAST(EVENT_TIMESTAMP_UTC AS DATE),'DDMMYYYY') < to_char(sysdate, 'DDMMYYYY'))
        AND OBJECT_NAME LIKE '&objectnamepattern'
        AND OBJECT_SCHEMA LIKE '&usernamepattern'
        AND DBUSERNAME LIKE '&usernamepattern'
        AND AUDIT_TYPE LIKE '&audittypepattern'
        AND RETURN_CODE LIKE '&returncodepattern'
;
