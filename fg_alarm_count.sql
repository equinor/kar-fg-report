DROP VIEW ISI.FG_ALARM_COUNT;

/* Formatted on 2016-12-12 08:20:32 (QP5 v5.256.13226.35510) */
CREATE OR REPLACE FORCE VIEW ISI.FG_ALARM_COUNT
(
   TAG,
   ALARMS
)
AS
     SELECT TAG, COUNT (TAG) AS ALARMS
       FROM FG_MAINT_ALARMS
   --WHERE TYPE_ID = 1
   GROUP BY TAG
   ORDER BY ALARMS DESC;