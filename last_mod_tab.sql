set line 220 pagesize 200 verify off

col TABLE_OWNER form A30
col TABLE_NAME form A30
col INSERTS form 99999
col UPDATES form 99999
col DELETES form 99999

accept begintimepattern prompt 'Enter begin time pattern (format YYYY/MM/DD HH24:MI:SS): '
accept endtimepattern prompt 'Enter end time pattern (format YYYY/MM/DD HH24:MI:SS): '


set linesize 500;
select TABLE_OWNER, TABLE_NAME, INSERTS, UPDATES, DELETES,
to_char(TIMESTAMP,'YYYY/MM/DD HH24:MI:SS') MOD_TIME
from all_tab_modifications
where table_owner<>'SYS' and
TIMESTAMP > TO_TIMESTAMP('&begintimepattern', 'YYYY/MM/DD HH24:MI:SS') AND TIMESTAMP > TO_TIMESTAMP('&endtimepattern', 'YYYY/MM/DD HH24:MI:SS')
order by 6;

