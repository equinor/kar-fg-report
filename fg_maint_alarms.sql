ALTER TABLE ISI.FG_MAINT_ALARMS
 DROP PRIMARY KEY CASCADE;

DROP TABLE ISI.FG_MAINT_ALARMS CASCADE CONSTRAINTS;

CREATE TABLE ISI.FG_MAINT_ALARMS
(
  ALARM_DATE        DATE                        NOT NULL,
  TAG               VARCHAR2(25 BYTE)           NOT NULL,
  DESCRIPTION       VARCHAR2(256 BYTE),
  COUNTER_1         INTEGER,
  COUNTER_2         INTEGER,
  FIRST_DATE        DATE,
  LAST_DATE         DATE,
  HOURS             INTEGER,
  RECOMENDATION_ID  INTEGER,
  TYPE_ID           INTEGER,
  COMMENTS          VARCHAR2(256 BYTE)
)
TABLESPACE CIM21
RESULT_CACHE (MODE DEFAULT)
PCTUSED    0
PCTFREE    10
INITRANS   1
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
LOGGING 
NOCOMPRESS 
NOCACHE
NOPARALLEL
MONITORING;


CREATE UNIQUE INDEX ISI.FG_MAINT_ALARMS_PK ON ISI.FG_MAINT_ALARMS
(ALARM_DATE, TAG)
LOGGING
TABLESPACE CIM21
PCTFREE    10
INITRANS   2
MAXTRANS   255
STORAGE    (
            INITIAL          64K
            NEXT             1M
            MAXSIZE          UNLIMITED
            MINEXTENTS       1
            MAXEXTENTS       UNLIMITED
            PCTINCREASE      0
            BUFFER_POOL      DEFAULT
            FLASH_CACHE      DEFAULT
            CELL_FLASH_CACHE DEFAULT
           )
NOPARALLEL;


CREATE OR REPLACE TRIGGER ISI.RECOMENDATION
/******************************************************************************
   NAME:       
   PURPOSE:    

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        06.12.2013      ROVO       1. Created this trigger.

   NOTES:

   Automatically available Auto Replace Keywords:
      Object Name:     
      Sysdate:         06.12.2013
      Date and Time:   06.12.2013, 11:24:10, and 06.12.2013 11:24:10
      Username:        ROVO (set in TOAD Options, Proc Templates)
      Table Name:      FG_MAINT_ALARMS (set in the "New PL/SQL Object" dialog)
      Trigger Options:  (set in the "New PL/SQL Object" dialog)
******************************************************************************/
BEFORE INSERT
ON ISI.FG_MAINT_ALARMS 
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   :NEW.HOURS := floor((:NEW.LAST_DATE - :NEW.FIRST_DATE) * 24);
   
   -- Flame Detector
   IF (:NEW.TYPE_ID = 2) THEN
     IF (:NEW.COUNTER_2 < 2 AND :NEW.HOURS > 20) THEN
       :NEW.RECOMENDATION_ID := 1;
     ELSIF (:NEW.COUNTER_2 >= 2 AND :NEW.HOURS > 20) THEN
       :NEW.RECOMENDATION_ID := 2;
     ELSIF (:NEW.COUNTER_2 >= 2 AND :NEW.HOURS < 20) THEN
       :NEW.RECOMENDATION_ID := 3;
     ELSIF (:NEW.COUNTER_2 < 2 AND :NEW.HOURS < 20) THEN
       :NEW.RECOMENDATION_ID := 4;
     END IF;

   -- Point Gas Detector
   ELSIF (:NEW.TYPE_ID = 1) THEN
     IF (:NEW.LAST_DATE = :NEW.ALARM_DATE AND :NEW.COUNTER_1 > 5) THEN
       :NEW.RECOMENDATION_ID := 5;
     ELSIF (:NEW.LAST_DATE = :NEW.ALARM_DATE AND :NEW.COUNTER_1 <= 5) THEN
       :NEW.RECOMENDATION_ID := 6;
     ELSIF (:NEW.LAST_DATE <> :NEW.ALARM_DATE AND :NEW.HOURS >= 50) THEN
       :NEW.RECOMENDATION_ID := 7;
     ELSIF (:NEW.LAST_DATE <> :NEW.ALARM_DATE AND :NEW.HOURS < 50) THEN
       :NEW.RECOMENDATION_ID := 8;
     END IF;

   -- Line Gas Detector
   ELSIF (:NEW.TYPE_ID = 3) THEN
     IF (:NEW.LAST_DATE = :NEW.ALARM_DATE AND :NEW.COUNTER_1 = :NEW.COUNTER_2) THEN
       :NEW.RECOMENDATION_ID := 9;
     ELSIF (:NEW.LAST_DATE = :NEW.ALARM_DATE AND :NEW.COUNTER_1 <> :NEW.COUNTER_2) THEN
       :NEW.RECOMENDATION_ID := 10;
     ELSIF (:NEW.LAST_DATE <> :NEW.ALARM_DATE AND :NEW.HOURS >= 50) THEN
       :NEW.RECOMENDATION_ID := 11;
     ELSIF (:NEW.LAST_DATE <> :NEW.ALARM_DATE AND :NEW.HOURS < 50) THEN
       :NEW.RECOMENDATION_ID := 12;
     END IF;
   END IF;
     
END ;
/


ALTER TABLE ISI.FG_MAINT_ALARMS ADD (
  CONSTRAINT FG_MAINT_ALARMS_PK
  PRIMARY KEY
  (ALARM_DATE, TAG)
  USING INDEX ISI.FG_MAINT_ALARMS_PK
  ENABLE VALIDATE);

ALTER TABLE ISI.FG_MAINT_ALARMS ADD (
  FOREIGN KEY (RECOMENDATION_ID) 
  REFERENCES ISI.FG_RECOMENDATION (ID)
  ENABLE VALIDATE,
  FOREIGN KEY (TYPE_ID) 
  REFERENCES ISI.FG_DETECTOR_TYPE (ID)
  ENABLE VALIDATE);
