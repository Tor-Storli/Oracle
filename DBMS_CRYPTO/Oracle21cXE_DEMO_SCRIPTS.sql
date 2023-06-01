SELECT object_name, object_type FROM dba_objects Where Owner = 'DEMO'

-- Remove any existing Objects if Schema exists
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_users WHERE username = 'DEMO';
  IF v_count = 1 THEN
        BEGIN
          FOR cur_rec IN (SELECT object_name, object_type FROM dba_objects Where Owner = 'DEMO') LOOP
            BEGIN
              EXECUTE IMMEDIATE ' DROP ' || cur_rec.object_type || ' "DEMO"."' || cur_rec.object_name || '"';
              DBMS_OUTPUT.PUT_LINE('Dropped object: DEMO.' || cur_rec.object_name);
            EXCEPTION
              WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error dropping: ' || cur_rec.object_name || '. ' || SQLERRM);
            END;
          END LOOP;
        END;
  END IF;
END;
/

--If role exist drop it
DROP ROLE DB_WEB_USER;

DECLARE
   v_count_user NUMBER;
BEGIN
   SELECT COUNT(*)
   INTO v_count_user
   FROM all_users
   WHERE username = 'WEB_APPLICATION';
  
   DBMS_OUTPUT.PUT_LINE('Error dropping user: ' || 'DROP USER WEB_APPLICATION CASCADE');
   IF v_count_user > 0 THEN
      EXECUTE IMMEDIATE 'DROP USER WEB_APPLICATION CASCADE';
   END IF;
END;
/

CREATE ROLE DB_WEB_USER;
  -- CREATE USER WEB_APPLICATION
CREATE USER "WEB_APPLICATION" IDENTIFIED BY "WEB_DEMO2023"  DEFAULT TABLESPACE "USERS" TEMPORARY TABLESPACE "TEMP";

    
CREATE TABLE "DEMO"."DEMO_ERROR_LOG" 
   ("DEMO_ERROR_LOG_ID" NUMBER(38,0), 
	"PROCEDURE_NAME" VARCHAR2(30 BYTE), 
	"PROCEDURE_STEP" VARCHAR2(1000 BYTE), 
	"CREATE_USERNAME" VARCHAR2(30 BYTE), 
	"ERROR_MSG" VARCHAR2(4000 BYTE), 
	"ERROR_CODE" VARCHAR2(20 BYTE), 
	"ACTIVE" CHAR(1 BYTE) DEFAULT 'Y', 
	"DEMO_CREATED_BY" VARCHAR2(50 BYTE) DEFAULT SYS_CONTEXT ('USERENV','SESSION_USER'), 
	"DEMO_CREATED_DATE" DATE DEFAULT SYSDATE, 
	"DEMO_MODIFIED_BY" VARCHAR2(50 BYTE), 
	"DEMO_MODIFIED_DATE" DATE
   );

  CREATE SEQUENCE  "DEMO"."SEQ_DEMO_ERROR_LOG"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE ;


CREATE TABLE DEMO.DEMO_SECURITY 
   ("DEMO_SECURITY_ID" NUMBER(10,0) NOT NULL,  
	"ENCRYPTED_TEXT" VARCHAR2(4000 CHAR), 
	"PASSWORD" VARCHAR2(100 CHAR) NOT NULL, 
	"USERID" VARCHAR2(50 CHAR) NOT NULL, 
	"ACTIVE" CHAR(1 BYTE) DEFAULT 'Y'  NOT NULL,
	"DEMO_CREATED_BY" VARCHAR2(50 BYTE) DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'), 
	"DEMO_CREATED_DATE" DATE DEFAULT SYSDATE, 
	"DEMO_MODIFIED_BY" VARCHAR2(50 BYTE), 
	"DEMO_MODIFIED_DATE" DATE);


    ALTER TABLE "DEMO"."DEMO_SECURITY" ADD CONSTRAINT "UK_USERID_01" UNIQUE ("USERID", "ACTIVE");


  CREATE SEQUENCE  "DEMO"."SEQ_DEMO_SECURITY"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE ;


CREATE TABLE DEMO.SECURITY_MASTER 
   ("SECURITY_MASTER_ID" NUMBER(15,0) NOT NULL, 
	"MASTER_KEY" VARCHAR2(200 CHAR)  NOT NULL, 
	"OBJECT_NAME" VARCHAR2(100 CHAR) NOT NULL, 
	"ACTIVE" CHAR(1 BYTE) DEFAULT 'Y' NOT NULL, 
	"DEMO_CREATED_BY" VARCHAR2(50 BYTE) DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'), 
	"DEMO_CREATED_DATE" DATE DEFAULT SYSDATE, 
	"DEMO_MODIFIED_BY" VARCHAR2(50 BYTE), 
	"DEMO_MODIFIED_DATE" DATE);

  CREATE SEQUENCE  "DEMO"."SEQ_SECURITY_MASTER"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE ;


CREATE TABLE "DEMO"."DEMO_USER_PROFILE" 
("DEMO_USER_PROFILE_ID" NUMBER(38,0) NOT NULL ENABLE, 
 "USERID" VARCHAR2(50 CHAR) NOT NULL ENABLE,
 "DEMO_USER_PROFILE_JSON" VARCHAR2(4000 CHAR),
 "ACTIVE" CHAR(1 BYTE) DEFAULT 'Y' NOT NULL ENABLE,
 "DEMO_CREATED_BY" VARCHAR2(50 BYTE) DEFAULT SYS_CONTEXT('USERENV','SESSION_USER'), 
 "DEMO_CREATED_DATE" DATE DEFAULT SYSDATE, 
 "DEMO_MODIFIED_BY" VARCHAR2(50 BYTE), 
 "DEMO_MODIFIED_DATE" DATE, 
 CONSTRAINT "UK_USERID_02" UNIQUE ("USERID", "ACTIVE")
);

CREATE SEQUENCE  "DEMO"."SEQ_DEMO_USER_PROFILE"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 NOCACHE  NOORDER  NOCYCLE;

--------------------------------------------------------
--  DDL for Function GET_APPLICATION_USER_NAME
--------------------------------------------------------

CREATE OR REPLACE FUNCTION "DEMO"."GET_APPLICATION_USER_NAME" RETURN varchar2 
IS
V_USERNAME varchar2(25);

begin
V_USERNAME := 'DEMOADMIN';

return V_USERNAME;
end GET_APPLICATION_USER_NAME;
/


--------------------------------------------------------
--  DDL for Trigger TRG_DEMO_ERROR_LOG_BU_MOD
--------------------------------------------------------

CREATE OR REPLACE TRIGGER "DEMO"."TRG_DEMO_ERROR_LOG_BU_MOD" BEFORE
UPDATE ON "DEMO"."DEMO_ERROR_LOG" FOR EACH ROW
DECLARE
   V_USERNAME VARCHAR2(25);

BEGIN

   --Query for the user name that the application uses to interact with the database
   SELECT GET_APPLICATION_USER_NAME() INTO V_USERNAME FROM DUAL;

   IF SYS_CONTEXT ('userenv', 'session_user') != V_USERNAME
   THEN  
      :NEW.DEMO_MODIFIED_BY    := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

   IF :NEW.DEMO_MODIFIED_BY IS NULL
   THEN 
      :NEW.DEMO_MODIFIED_BY   := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

     -- Database always determines date    
   :NEW.DEMO_MODIFIED_DATE := SYSDATE;

END TRG_DEMO_ERROR_LOG_BU_MOD;
/
ALTER TRIGGER "DEMO"."TRG_DEMO_ERROR_LOG_BU_MOD" ENABLE;

--------------------------------------------------------
--  DDL for Trigger TRG_SEQ_DEMO_ERROR_LOG_BIU
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "DEMO"."TRG_SEQ_DEMO_ERROR_LOG_BIU" BEFORE
  INSERT OR
  UPDATE ON DEMO.DEMO_ERROR_LOG FOR EACH ROW
  DECLARE V_NEXTVAL NUMBER;
  CANNOT_CHANGE_AUTONUMBER EXCEPTION;
  BEGIN
    IF INSERTING THEN
      IF :NEW.DEMO_ERROR_LOG_ID IS NULL THEN
        SELECT SEQ_DEMO_ERROR_LOG.NEXTVAL INTO V_NEXTVAL FROM DUAL;
        :NEW.DEMO_ERROR_LOG_ID := V_NEXTVAL;
      END IF;
      -- Database always determines date    
     :NEW.DEMO_CREATED_DATE := SYSDATE;
     :NEW.DEMO_MODIFIED_BY := NULL;
     :NEW.DEMO_MODIFIED_DATE := NULL;
      
    END IF; -- End of Inserting Code
    IF UPDATING THEN
      -- Do not allow the PK to be changed.
      IF NOT(:NEW.DEMO_ERROR_LOG_ID = :OLD.DEMO_ERROR_LOG_ID) THEN
        RAISE CANNOT_CHANGE_AUTONUMBER;
      END IF;
    END IF; -- End of Updating Code
  EXCEPTION
  WHEN CANNOT_CHANGE_AUTONUMBER THEN
    raise_application_error(-20101,'TRG_SEQ_DEMO_ERROR_LOG_BIU - Cannot Change AUTONUMBER Value:  '||sqlerrm||':  '||SQLCODE);
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20102,'TRG_SEQ_DEMO_ERROR_LOG_BIU Value:  '||SQLERRM||':  '||SQLCODE);
  END TRG_SEQ_DEMO_ERROR_LOG_BIU;
/
ALTER TRIGGER "DEMO"."TRG_SEQ_DEMO_ERROR_LOG_BIU" ENABLE;

--------------------------------------------------------
--  DDL for Trigger TRG_SECURITY_MASTER_BU_MOD
--------------------------------------------------------

CREATE OR REPLACE TRIGGER "DEMO"."TRG_SECURITY_MASTER_BU_MOD" BEFORE
UPDATE ON "DEMO"."SECURITY_MASTER" FOR EACH ROW
DECLARE
   V_USERNAME VARCHAR2(25);
BEGIN

   --Query for the user name that the application uses to interact with the database
   SELECT GET_APPLICATION_USER_NAME() INTO V_USERNAME FROM DUAL;

   IF SYS_CONTEXT ('userenv', 'session_user') != V_USERNAME
   THEN  
      :NEW.DEMO_MODIFIED_BY    := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

   IF :NEW.DEMO_MODIFIED_BY IS NULL
   THEN 
      :NEW.DEMO_MODIFIED_BY   := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

     -- Database always determines date    
   :NEW.DEMO_MODIFIED_DATE := SYSDATE;

END TRG_SECURITY_MASTER_BU_MOD;
/
ALTER TRIGGER "DEMO"."TRG_SECURITY_MASTER_BU_MOD" ENABLE;

--------------------------------------------------------
--  DDL for Trigger TRG_SEQ_SECURITY_MASTER_BIU
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "DEMO"."TRG_SEQ_SECURITY_MASTER_BIU" BEFORE
  INSERT OR
  UPDATE ON DEMO.SECURITY_MASTER FOR EACH ROW
  DECLARE V_NEXTVAL NUMBER;
  CANNOT_CHANGE_AUTONUMBER EXCEPTION;
  BEGIN
    IF INSERTING THEN
      IF :NEW.SECURITY_MASTER_ID IS NULL THEN
         SELECT SEQ_SECURITY_MASTER.NEXTVAL INTO V_NEXTVAL FROM DUAL;
        :NEW.SECURITY_MASTER_ID := V_NEXTVAL;
      END IF;
      -- Database always determines date    
     :NEW.DEMO_CREATED_DATE := SYSDATE;
     :NEW.DEMO_MODIFIED_BY := NULL;
     :NEW.DEMO_MODIFIED_DATE := NULL;
      
    END IF; -- End of Inserting Code
    IF UPDATING THEN
      -- Do not allow the PK to be changed.
      IF NOT(:NEW.SECURITY_MASTER_ID = :OLD.SECURITY_MASTER_ID) THEN
        RAISE CANNOT_CHANGE_AUTONUMBER;
      END IF;
    END IF; -- End of Updating Code
  EXCEPTION
  WHEN CANNOT_CHANGE_AUTONUMBER THEN
    raise_application_error(-20101,'TRG_SEQ_SECURITY_MASTER_BIU - Cannot Change AUTONUMBER Value:  '||sqlerrm||':  '||SQLCODE);
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20102,'TRG_SEQ_SECURITY_MASTER_BIU Value:  '||SQLERRM||':  '||SQLCODE);
  END TRG_SEQ_SECURITY_MASTER_BIU;
/
ALTER TRIGGER "DEMO"."TRG_SEQ_SECURITY_MASTER_BIU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger TRG_DEMO_SECURITY_BU_MOD
--------------------------------------------------------

CREATE OR REPLACE TRIGGER "DEMO"."TRG_DEMO_SECURITY_BU_MOD" BEFORE
UPDATE ON "DEMO"."DEMO_SECURITY" FOR EACH ROW
DECLARE
   V_USERNAME VARCHAR2(25);

BEGIN

   --Query for the user name that the application uses to interact with the database
   SELECT GET_APPLICATION_USER_NAME() INTO V_USERNAME FROM DUAL;

   IF SYS_CONTEXT ('userenv', 'session_user') != V_USERNAME
   THEN  
      :NEW.DEMO_MODIFIED_BY    := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

   IF :NEW.DEMO_MODIFIED_BY IS NULL
   THEN 
      :NEW.DEMO_MODIFIED_BY   := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

     -- Database always determines date    
   :NEW.DEMO_MODIFIED_DATE := SYSDATE;

END TRG_DEMO_SECURITY_BU_MOD;
/
ALTER TRIGGER "DEMO"."TRG_DEMO_SECURITY_BU_MOD" ENABLE;

--------------------------------------------------------
--  DDL for Trigger TRG_SEQ_DEMO_SECURITY_BIU
--------------------------------------------------------

  CREATE OR REPLACE TRIGGER "DEMO"."TRG_SEQ_DEMO_SECURITY_BIU" BEFORE
  INSERT OR
  UPDATE ON DEMO.DEMO_SECURITY FOR EACH ROW
  DECLARE V_NEXTVAL NUMBER;
  CANNOT_CHANGE_AUTONUMBER EXCEPTION;
  BEGIN
    IF INSERTING THEN
      IF :NEW.DEMO_SECURITY_ID IS NULL THEN
         SELECT SEQ_DEMO_SECURITY.NEXTVAL INTO V_NEXTVAL FROM DUAL;
        :NEW.DEMO_SECURITY_ID := V_NEXTVAL;
      END IF;
      -- Database always determines date    
     :NEW.DEMO_CREATED_DATE := SYSDATE;
     :NEW.DEMO_MODIFIED_BY := NULL;
     :NEW.DEMO_MODIFIED_DATE := NULL;
      
    END IF; -- End of Inserting Code
    IF UPDATING THEN
      -- Do not allow the PK to be changed.
      IF NOT(:NEW.DEMO_SECURITY_ID = :OLD.DEMO_SECURITY_ID) THEN
        RAISE CANNOT_CHANGE_AUTONUMBER;
      END IF;
    END IF; -- End of Updating Code
  EXCEPTION
  WHEN CANNOT_CHANGE_AUTONUMBER THEN
    raise_application_error(-20101,'TRG_SEQ_DEMO_SECURITY_BIU - Cannot Change AUTONUMBER Value:  '||sqlerrm||':  '||SQLCODE);
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20102,'TRG_SEQ_DEMO_SECURITY_BIU Value:  '||SQLERRM||':  '||SQLCODE);
  END TRG_SEQ_DEMO_SECURITY_BIU;
/
ALTER TRIGGER "DEMO"."TRG_SEQ_DEMO_SECURITY_BIU" ENABLE;


--------------------------------------------------------
--  DDL for Trigger TRG_DEMO_USER_PROFILE_BU_MOD
--------------------------------------------------------
create or replace TRIGGER "DEMO"."TRG_DEMO_USER_PROFILE_BU_MOD" BEFORE
UPDATE ON "DEMO"."DEMO_USER_PROFILE" FOR EACH ROW
DECLARE
   V_USERNAME VARCHAR2(25);

BEGIN

   --Query for the user name that the application uses to interact with the database
   SELECT GET_APPLICATION_USER_NAME() INTO V_USERNAME FROM DUAL;

   IF SYS_CONTEXT ('userenv', 'session_user') != V_USERNAME
   THEN
      :NEW.DEMO_MODIFIED_BY    := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

   IF :NEW.DEMO_MODIFIED_BY IS NULL
   THEN
      :NEW.DEMO_MODIFIED_BY   := SYS_CONTEXT ('userenv', 'session_user');
   END IF;

     -- Database always determines date
   :NEW.DEMO_MODIFIED_DATE := SYSDATE;

END TRG_DEMO_USER_PROFILE_BU_MOD;
/
ALTER TRIGGER "DEMO"."TRG_DEMO_USER_PROFILE_BU_MOD" ENABLE;

--------------------------------------------------------
--  DDL for Trigger TRG_SEQ_DEMO_USER_PROFILE_BIU
--------------------------------------------------------
create or replace TRIGGER "DEMO"."TRG_SEQ_DEMO_USER_PROFILE_BIU" BEFORE
  INSERT OR
  UPDATE ON DEMO.DEMO_USER_PROFILE FOR EACH ROW
  DECLARE V_NEXTVAL NUMBER;
  CANNOT_CHANGE_AUTONUMBER EXCEPTION;
  BEGIN
    IF INSERTING THEN
      IF :NEW.DEMO_USER_PROFILE_ID IS NULL THEN
        SELECT SEQ_DEMO_USER_PROFILE.NEXTVAL INTO V_NEXTVAL FROM DUAL;
        :NEW.DEMO_USER_PROFILE_ID := V_NEXTVAL;
      END IF;
      -- Database always determines date
     :NEW.DEMO_CREATED_DATE := SYSDATE;
     :NEW.DEMO_MODIFIED_BY := NULL;
     :NEW.DEMO_MODIFIED_DATE := NULL;

    END IF; -- End of Inserting Code
    IF UPDATING THEN
      -- Do not allow the PK to be changed.
      IF NOT(:NEW.DEMO_USER_PROFILE_ID = :OLD.DEMO_USER_PROFILE_ID) THEN
        RAISE CANNOT_CHANGE_AUTONUMBER;
      END IF;
    END IF; -- End of Updating Code
  EXCEPTION
  WHEN CANNOT_CHANGE_AUTONUMBER THEN
    raise_application_error(-20101,'TRG_SEQ_DEMO_USER_PROFILE_BIU - Cannot Change AUTONUMBER Value:  '||sqlerrm||':  '||SQLCODE);
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20102,'TRG_SEQ_DEMO_USER_PROFILE_BIU Value:  '||SQLERRM||':  '||SQLCODE);
  END TRG_SEQ_DEMO_USER_PROFILE_BIU;
/
ALTER TRIGGER "DEMO"."TRG_SEQ_DEMO_USER_PROFILE_BIU" ENABLE;

--------------------------------------------------------
--  DDL for Package DEMO_UTILITIES_PKG
--------------------------------------------------------

CREATE OR REPLACE PACKAGE DEMO.DEMO_UTILITIES_PKG
AS
  PROCEDURE DEMOLOG_ERROR_MSG (
                      V_PROCNAME_IN IN DEMO_ERROR_LOG.PROCEDURE_NAME%TYPE,
                      V_PROCSTEP_IN IN DEMO_ERROR_LOG.PROCEDURE_STEP%TYPE,
                      V_USERNAME_IN IN DEMO_ERROR_LOG.CREATE_USERNAME%TYPE,
                      V_ERRORMSG_IN IN DEMO_ERROR_LOG.ERROR_MSG%TYPE,
                      V_ERRORCODE_IN IN DEMO_ERROR_LOG.ERROR_CODE%TYPE);
  END DEMO_UTILITIES_PKG;
/


--------------------------------------------------------
--  DDL for Package Body DEMO_UTILITIES_PKG
--------------------------------------------------------

  CREATE OR REPLACE PACKAGE BODY DEMO.DEMO_UTILITIES_PKG
    AS

       PROCEDURE DEMOLOG_ERROR_MSG (
                                   V_PROCNAME_IN IN DEMO_ERROR_LOG.PROCEDURE_NAME%TYPE,
                                   V_PROCSTEP_IN IN DEMO_ERROR_LOG.PROCEDURE_STEP%TYPE,
                                   V_USERNAME_IN IN DEMO_ERROR_LOG.CREATE_USERNAME%TYPE,
                                   V_ERRORMSG_IN IN DEMO_ERROR_LOG.ERROR_MSG%TYPE,
                                   V_ERRORCODE_IN IN DEMO_ERROR_LOG.ERROR_CODE%TYPE)

   /**********************************************************************************************
    *     NAME:           DEMOLOG_ERROR_MSG
    *     CREATOR:        Tor Storli
    *     DATE:           05/14/2023
    *
    *     SUMMARY:        The procedure inserts error records into the error log table.
    *                     This procedure can be used by all functions or procedures
    *                     to maintain a central point of entry for error logging. The procedure
    *                     can be called from the EXCEPTION Handler in the individual function
    *                     or procedure.
    *
    *     REVISIONS:
    *
    ***********************************************************************************************/
    AS
    
           -- ERROR HANDLING VARIABLES
               V_ERRORMSG         DEMO_ERROR_LOG.ERROR_MSG%TYPE;                              -- database error message
               V_ERRCODE          DEMO_ERROR_LOG.ERROR_CODE%TYPE;                             -- database error number
               C_PROCNAME         DEMO_ERROR_LOG.PROCEDURE_NAME%TYPE := 'DEMOLOG_ERROR_MSG';  -- procedure name
               V_PROCSTEP         DEMO_ERROR_LOG.PROCEDURE_STEP%TYPE;                         -- line number in procedure  
    
    BEGIN
    
     INSERT INTO DEMO.DEMO_ERROR_LOG
                   ( PROCEDURE_NAME,
                     PROCEDURE_STEP,
                     CREATE_USERNAME,
                     ERROR_MSG,
                     ERROR_CODE,
                     DEMO_CREATED_BY,
                     DEMO_CREATED_DATE)
     VALUES
                    (V_PROCNAME_IN,
                     V_PROCSTEP_IN,
                     V_USERNAME_IN,
                     V_ERRORMSG_IN,
                     V_ERRORCODE_IN,
                     USER,
                     SYSDATE
                  );
    
      COMMIT;
    
    EXCEPTION
     WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20101,C_PROCNAME||':  '||V_ERRORMSG||':  '||V_ERRCODE);
    
    END DEMOLOG_ERROR_MSG;
END DEMO_UTILITIES_PKG;
/


DECLARE         
     --Create an ecrypted Master Key to be used in the STOR Schema
       V_DEMOMASTER_KEY VARCHAR2(2000);       
BEGIN
       EXECUTE IMMEDIATE 'TRUNCATE TABLE DEMO.SECURITY_MASTER DROP STORAGE';
       
       V_DEMOMASTER_KEY := 'DEMO_MASTER_KEY1';

       INSERT INTO DEMO.SECURITY_MASTER(MASTER_KEY, OBJECT_NAME)
       VALUES (V_DEMOMASTER_KEY, 'DEMO_SECURITY');
       
       COMMIT;
       
       DBMS_OUTPUT.PUT_LINE ('V_DEMOMASTER_KEY='||V_DEMOMASTER_KEY);
END;     
/

/***** Insert DEMO Master Key for the DEMO_SECURITY Table ******/
--INSERT INTO DEMO.SECURITY_MASTER(MASTER_KEY, OBJECT_NAME)
--VALUES('DEMOMaster_Key12345','DEMO_SECURITY');

--COMMIT;

/***** Insert DEMO Master Key for the DEMO_SECURITY Table ******/
INSERT INTO DEMO.DEMO_SECURITY(PASSWORD, USERID)
VALUES('DEMO$1','DEMO');

COMMIT;

DECLARE

JSON_THEME VARCHAR2(4000) := '{
  "theme": {
    "primary": "#3f51b5",
    "secondary": "#b0bec5",
    "accent": "#8c9eff",
    "error": "#b71c1c"
  },
  "darkMode": true,
  "fontSize": 16,
  "fontFamily": "Roboto"
}';

BEGIN
  INSERT INTO DEMO.DEMO_USER_PROFILE(USERID, DEMO_USER_PROFILE_JSON)
  VALUES('DEMO',JSON_THEME);
  
  COMMIT;
END;
/
create or replace PACKAGE "DEMO"."DEMO_SECURITY_PKG"
  /************************************************************************************************************************************
    *   Name:              DEMO_SECURITY_PKG
    *   Creator:           Tor Storli
    *   Date:              05/23/2023
    *
    *   Summary:           This Package encrypts, decrypts and generates hash codes for an Application. It demonstrates how you can use
    *                      the DBMS_CRYPTO Package to manually customize the security functionallity of an Application. 
    *
    *   Notes:            1) The raise_application_error used in the functions in the package is actually a procedure defined by Oracle
    *                        that allows the developer to raise an exception and associate an error number and message with the procedure. 
    *                        This allows the application to raise application errors rather than just Oracle errors. 
    *                        Error numbers are defined between -20,000 and -20,999.
    *
    *                     2) In order to execute the DBMS_CRYPTO Package you need to 
    *                            1) Explore the process of using "Invoker Rights", not "Definer Rights" (default)
    *                               For Example: Even if you inclued the following statement in the Grant Role privileges, it will
    *                                            not work because Database Roles are ignored completely when stored programs are compiling. 
    *                                            All privileges must be granted directly to the definer(owner) of the program.
    *
    *                               Whenever you run a program compiled with the definer rights (default), 
    *                               its SQL executes under the authority of the schema that owns the program. 
    *                               For the DBMS_CRYPTO package - that is the SYS Schema. In order for you to compile this package the following
    *                               GRANT must me made (in this context: in the SYS Schema logged in as SYSDBA):
    *                               A. Log in to the SYS Schema.
    *                               B. Run this statement as SYSDBA:
    *                             
    *                                  -- Need to run the following command for the package to compile:  
    *                                     GRANT EXECUTE ON SYS.DBMS_CRYPTO TO DEMO;
    *                                                  
    *
    *   Revisions:  
    *                          
    *
    *************************************************************************************************************************************/
AS
    FUNCTION ENCRYPT_DATA (V_USERID_IN VARCHAR2, V_USER_KEY_IN VARCHAR2, V_TEXT_2_ENCRYPT_IN  VARCHAR2) RETURN VARCHAR2;
    FUNCTION DECRYPT_DATA (V_USERID_IN VARCHAR2, V_USER_KEY_IN VARCHAR2) RETURN VARCHAR2;
    FUNCTION CREATE_UPDATE_USER(V_USERID_IN VARCHAR2, V_PASSWORD_IN  VARCHAR2) RETURN VARCHAR2;
    FUNCTION VERIFY_USER(V_USERID_IN VARCHAR2, V_PASSWORD_IN  VARCHAR2) RETURN VARCHAR2;
END;
/

create or replace PACKAGE BODY "DEMO"."DEMO_SECURITY_PKG"
AS
    FUNCTION ENCRYPT_DATA(V_USERID_IN VARCHAR2, V_USER_KEY_IN VARCHAR2, V_TEXT_2_ENCRYPT_IN  varchar2)
             
           /************************************************************************************************************************************
            *   Name:              ENCRYPT_DATA
            *   Creator:           Tor Storli
            *   Date:              05/14/2023
            *
            *   Summary:           This Function encrypt a parameter text supplied by user. 
            *
            *                      Parameter(s):  V_USERID_IN
			*                                     V_USER_KEY_IN
			*                                     V_TEXT_2_ENCRYPT_IN
            *                                                  
            *  Revisions:  
            *                          
            *
            *************************************************************************************************************************************/
    RETURN VARCHAR2
    AS

            -- Error Handling Variables
               V_ERRORMSG         DEMO_ERROR_LOG.ERROR_MSG%TYPE;                        -- database error message
               V_ERRCODE          DEMO_ERROR_LOG.ERROR_CODE%TYPE;                       -- database error number
               C_PROCNAME         DEMO_ERROR_LOG.PROCEDURE_NAME%TYPE := 'ENCRYPT_DATA'; -- procedure name                       
               V_PROCSTEP         DEMO_ERROR_LOG.PROCEDURE_STEP%TYPE;                   -- line number in procedure 

            -- Declare custom Exception
               USER_DO_NOT_EXIST EXCEPTION;
 
             --Local Variables
               V_ROW_COUNT Number(3,0);
               V_MESSAGE VARCHAR2(50);
               SECURITY_MASTER_KEY VARCHAR2(2000 CHAR);   
               V_ALGORITHM NUMBER := DBMS_CRYPTO.ENCRYPT_AES128
                                   + DBMS_CRYPTO.CHAIN_CBC
                                   + DBMS_CRYPTO.PAD_PKCS5;
               V_ENCRYPT     RAW (2000);
               V_ENCRYPT_KEY RAW (2000);

    BEGIN
    
        -- Get Master Key from Security_Master Table
           SELECT MASTER_KEY INTO SECURITY_MASTER_KEY 
           FROM DEMO.SECURITY_MASTER 
           WHERE OBJECT_NAME = 'DEMO_SECURITY'
           AND ACTIVE = 'Y';
          
        -- Verify that the User is in the DEMO_SECURITY Table
           SELECT COUNT(USERID) INTO V_ROW_COUNT 
           FROM DEMO.DEMO_SECURITY 
           WHERE USERID = V_USERID_IN
           AND ACTIVE = 'Y';
          
        -- If User do not Exist - Exit Function
           IF V_ROW_COUNT = 0 THEN
              RAISE USER_DO_NOT_EXIST;
           END IF;
           
        V_ENCRYPT_KEY := UTL_RAW.BIT_XOR (
           UTL_I18N.STRING_TO_RAW (V_USER_KEY_IN, 'AL32UTF8'),
           UTL_I18N.STRING_TO_RAW (SECURITY_MASTER_KEY, 'AL32UTF8')
        );
        V_ENCRYPT := DBMS_CRYPTO.encrypt
           (
              UTL_I18N.STRING_TO_RAW (V_TEXT_2_ENCRYPT_IN, 'AL32UTF8'),
              V_ALGORITHM,
              V_ENCRYPT_KEY
           );
        DBMS_OUTPUT.PUT_LINE('Encrypted='||V_ENCRYPT);
        
      
        IF V_ROW_COUNT = 1 THEN
             -- Update existing User's Encrypted Text field in the DEMO_SECURITY Database table
                UPDATE DEMO.DEMO_SECURITY
                SET ENCRYPTED_TEXT = V_ENCRYPT
                WHERE USERID = V_USERID_IN
                AND ACTIVE = 'Y';
                
                V_MESSAGE := 'Record Updated';
 
                IF SQL%ROWCOUNT = 1 THEN
                   COMMIT;
                   RETURN(V_MESSAGE);
                ELSE
                   ROLLBACK;
                   RETURN NULL;
                END IF;
  
         END IF;
         
      EXCEPTION
        WHEN USER_DO_NOT_EXIST THEN 
            RAISE_APPLICATION_ERROR(-20104,'User Does Not Exist');     
            RETURN(NULL);
            
          WHEN OTHERS THEN

           --load error variables
              V_PROCSTEP := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
              V_ERRORMSG := SUBSTR(SQLERRM,1,200);
              V_ERRCODE  := sqlcode;

              --log error message
                DEMO_UTILITIES_PKG.DEMOLOG_ERROR_MSG(C_PROCNAME, V_PROCSTEP, USER,V_ERRORMSG, V_ERRCODE);

              --Raise Application Error
                RAISE_APPLICATION_ERROR(-20103,C_PROCNAME||':  '||V_ERRORMSG||':  '||V_ERRCODE);           
END ENCRYPT_DATA;

FUNCTION DECRYPT_DATA(V_USERID_IN VARCHAR2, V_USER_KEY_IN VARCHAR2)

           /************************************************************************************************************************************
            *   Name:              DECRYPT_DATA
            *   Creator:           Tor Storli
            *   Date:              05/14/2023
            *
            *   Summary:            This Function decrypt the text the User stored in the SECURITY_MASTER table
            *
            *                       Parameter(s):  V_USERID_IN 
			*                                      V_USER_KEY_IN 
			*                                      V_TEXT_2_DECRYPT_IN
            *                                                  
            *  Revisions:  
            *                          
            *
            *************************************************************************************************************************************/
    RETURN VARCHAR2
    AS

            -- Error Handling Variables
               V_ERRORMSG         DEMO_ERROR_LOG.ERROR_MSG%TYPE;                        -- database error message
               V_ERRCODE          DEMO_ERROR_LOG.ERROR_CODE%type;                       -- database error number
               C_PROCNAME         DEMO_ERROR_LOG.PROCEDURE_NAME%type := 'DECRYPT_DATA'; -- procedure name                       
               V_PROCSTEP         DEMO_ERROR_LOG.PROCEDURE_STEP%type;                   -- line number in procedure 

            -- Declare custom Exception
               USER_DO_NOT_EXIST EXCEPTION;

               --Local Variables
               V_ROW_COUNT NUMBER(3,0);
               V_TEXT_RAW RAW(2000);
               SECURITY_MASTER_KEY varchar2(2000);
               V_TEXT_2_DECRYPT  Varchar2 (2000);
               V_ALGORITHM     number := DBMS_CRYPTO.ENCRYPT_AES128
                                       + DBMS_CRYPTO.CHAIN_CBC
                                       + DBMS_CRYPTO.PAD_PKCS5;
               V_DECRYPTED   RAW (2000);
               V_DECRYPT_KEY RAW (2000);-- current stepline  in procedure  
    BEGIN
         -- Get Master Key from Security_Master Table
           SELECT MASTER_KEY INTO SECURITY_MASTER_KEY 
           FROM DEMO.SECURITY_MASTER 
           WHERE OBJECT_NAME = 'DEMO_SECURITY'
           AND ACTIVE = 'Y';
           
        -- Verify that the User is in the DEMO_SECURITY Table
           SELECT COUNT(USERID) INTO V_ROW_COUNT 
           FROM DEMO.DEMO_SECURITY 
           WHERE USERID = V_USERID_IN
           AND ACTIVE = 'Y';
           
        -- If User do not Exist - Exit Function
           IF V_ROW_COUNT = 0 THEN
              RAISE USER_DO_NOT_EXIST;
           END IF;
           
        -- Get Encrypted Text for the User stored in the DEMO_SECURITY Table
           SELECT ENCRYPTED_TEXT INTO V_TEXT_2_DECRYPT 
           FROM DEMO.DEMO_SECURITY 
           WHERE USERID = V_USERID_IN
           AND ACTIVE = 'Y';
        
        -- Convert to RAW Datatype		
           V_TEXT_RAW := HEXTORAW(V_TEXT_2_DECRYPT);
           
		--Combine User Key and Master Key   
           V_DECRYPT_KEY := utl_raw.bit_xor (
                UTL_I18N.STRING_TO_RAW (V_USER_KEY_IN, 'AL32UTF8'),
                UTL_I18N.STRING_TO_RAW (SECURITY_MASTER_KEY, 'AL32UTF8')
           );
       
	    --Decrypt Raw Text
           V_DECRYPTED := DBMS_CRYPTO.DECRYPT
           (
              V_TEXT_RAW,
              V_ALGORITHM,
              V_DECRYPT_KEY
           );
           
         --  dbms_output.put_line ('Decrypted='||utl_i18n.raw_to_char(V_DECRYPTED));
         
		 --Return Clear Text of Decrypted Raw Text to User
           RETURN(UTL_I18N.RAW_TO_CHAR(V_DECRYPTED));
           
    EXCEPTION
        WHEN USER_DO_NOT_EXIST THEN 
            RAISE_APPLICATION_ERROR(-20104,'User Does Not Exist');     
            RETURN(NULL);
 
         WHEN OTHERS THEN

           --load error variables
              V_PROCSTEP := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
              V_ERRORMSG := SUBSTR(SQLERRM,1,200);
              V_ERRCODE  := sqlcode;

              --log error message
                DEMO_UTILITIES_PKG.DEMOLOG_ERROR_MSG(C_PROCNAME, V_PROCSTEP, USER,V_ERRORMSG, V_ERRCODE);

              --Raise Application Error
                RAISE_APPLICATION_ERROR(-20103,C_PROCNAME||':  '||V_ERRORMSG||':  '||V_ERRCODE);           
END DECRYPT_DATA;


FUNCTION CREATE_UPDATE_USER(V_USERID_IN VARCHAR2, V_PASSWORD_IN  VARCHAR2)

           /************************************************************************************************************************************
            *   Name:              CREATE_USER
            *   Creator:           Tor Storli
            *   Date:              05/18/2023
            *
            *   Summary:           This Function Creates a new user based on data supplied by user. 
            *
            *                      Parameter(s):  V_USERID_IN
            *                                     V_PASSWORD_IN           
            *  Revisions:  
            *                          
            *
            *************************************************************************************************************************************/
    RETURN VARCHAR2
    AS

        -- Error Handling Variables
           V_ERRORMSG         DEMO_ERROR_LOG.ERROR_MSG%TYPE;                               -- database error message
           V_ERRCODE          DEMO_ERROR_LOG.ERROR_CODE%type;                              -- database error number
           C_PROCNAME         DEMO_ERROR_LOG.PROCEDURE_NAME%type := 'CREATE_UPDATE_USER';  -- procedure name                        
           V_PROCSTEP         DEMO_ERROR_LOG.PROCEDURE_STEP%type;                          -- line number in procedure 

        -- Local Variables  
           V_MESSAGE VARCHAR2(50);
           V_ROW_COUNT Number(3,0);
           V_USERID VARCHAR2(50);
           RAW_PASSWORD_IN RAW(128);
           ENCRYPTED_PSW RAW(128);
           SECURITY_MASTER_KEY VARCHAR2(200 CHAR);
           SECURITY_MASTER_KEY_RAW RAW(128);
    BEGIN
        -- Get Master Key from Security_Master Table
           SELECT MASTER_KEY INTO SECURITY_MASTER_KEY 
           FROM DEMO.SECURITY_MASTER 
           WHERE OBJECT_NAME = 'DEMO_SECURITY'
           AND ACTIVE = 'Y';

        -- Verify existence of User in the DEMO_SECURITY Table
           SELECT COUNT(USERID) INTO V_ROW_COUNT 
           FROM DEMO.DEMO_SECURITY 
           WHERE USERID = V_USERID_IN
           AND ACTIVE = 'Y';
                   
        -- Convert Security Master Key into RAW
           SECURITY_MASTER_KEY_RAW := UTL_RAW.CAST_TO_RAW(CONVERT(SECURITY_MASTER_KEY,'AL32UTF8','US7ASCII'));
           
        -- Convert User Supplied Password To Raw    
           RAW_PASSWORD_IN := UTL_RAW.CAST_TO_RAW(CONVERT(V_PASSWORD_IN,'AL32UTF8','US7ASCII'));
 
        -- Encrypt User Supplied Password - Add MAC  
           ENCRYPTED_PSW := DBMS_CRYPTO.MAC(SRC => RAW_PASSWORD_IN,  TYP => DBMS_CRYPTO.HMAC_MD5, KEY => SECURITY_MASTER_KEY_RAW);

          IF V_ROW_COUNT = 1 THEN
             -- Update existing User's Password in the DEMO_SECURITY Database table
                UPDATE DEMO.DEMO_SECURITY
                SET PASSWORD = ENCRYPTED_PSW
                WHERE USERID = V_USERID_IN
                AND ACTIVE = 'Y';
                
                V_MESSAGE := 'Record Updated';
          ELSE
             -- Add data to DEMO_SECURITY Database table
                INSERT INTO DEMO.DEMO_SECURITY(PASSWORD, USERID)
                VALUES(ENCRYPTED_PSW, V_USERID_IN);
               
                V_MESSAGE := 'Record Inserted';
         END IF;
          
          IF SQL%ROWCOUNT = 1 THEN
             COMMIT;
             RETURN(V_MESSAGE);
          ELSE
             ROLLBACK;
             RETURN NULL;
          END IF;
         
    EXCEPTION            
         WHEN OTHERS THEN
          --load error variables
            V_PROCSTEP := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            V_ERRORMSG := SUBSTR(SQLERRM,1,200);
            V_ERRCODE  := sqlcode;

          --log error message
            DEMO_UTILITIES_PKG.DEMOLOG_ERROR_MSG(C_PROCNAME, V_PROCSTEP, USER,V_ERRORMSG, V_ERRCODE);

          --Raise Application Error
            RAISE_APPLICATION_ERROR(-20103,C_PROCNAME||':  '||V_ERRORMSG||':  '||V_ERRCODE);           
    END CREATE_UPDATE_USER;
    
--    
FUNCTION VERIFY_USER(V_USERID_IN VARCHAR2, V_PASSWORD_IN  VARCHAR2)

      /************************************************************************************************************************************
        *   Name:              VERIFY_USER
        *   Creator:           Tor Storli
        *   Date:              05/18/2023
        *
        *   Summary:           This Function HASH a parameter password supplied by user
        *                      and compares it what is in the database. If they match - User will be validated
        *
        *                      Parameter(s):  V_USERID
        *                                     V_PASSWORD_IN           
        *  Revisions:  
        *                          
        *
        *************************************************************************************************************************************/
    RETURN VARCHAR2
    AS

        -- Error Handling Variables
           V_ERRORMSG         DEMO_ERROR_LOG.ERROR_MSG%TYPE;                       -- database error message
           V_ERRCODE          DEMO_ERROR_LOG.ERROR_CODE%type;                      -- database error number
           C_PROCNAME         DEMO_ERROR_LOG.PROCEDURE_NAME%type := 'VERIFY_USER'; -- procedure name                        
           V_PROCSTEP         DEMO_ERROR_LOG.PROCEDURE_STEP%type;                  -- line number in procedure 

       -- Declare custom Exception
          USER_DO_NOT_EXIST EXCEPTION;
 
        -- Local Variables  
           V_ROW_COUNT Number(3,0);
           V_USERID VARCHAR2(50);
           V_PASSWORD_DB VARCHAR2(50);
           RAW_PASSWORD_IN RAW(128);
           RAW_PASSWORD_DB RAW(128);
           ENCRYPTED_PSW RAW(128);
           SECURITY_MASTER_KEY VARCHAR2(200 CHAR);
           SECURITY_MASTER_KEY_RAW RAW(128);
    BEGIN
        -- Get Master Key from Security_Master Table
           SELECT MASTER_KEY INTO SECURITY_MASTER_KEY 
           FROM DEMO.SECURITY_MASTER 
           WHERE OBJECT_NAME = 'DEMO_SECURITY'
           AND ACTIVE = 'Y';

        -- Verify that the User is not in the DEMO_SECURITY Table
           SELECT COUNT(USERID) INTO V_ROW_COUNT 
           FROM DEMO.DEMO_SECURITY 
           WHERE USERID = V_USERID_IN
           AND ACTIVE = 'Y';
           
        -- If User do not Exist - Exit Function
           IF V_ROW_COUNT = 0 THEN
              RAISE USER_DO_NOT_EXIST;
           END IF;
        
        -- Retrieve the existing User password from the DEMO_SECURITY Table
           SELECT PASSWORD INTO V_PASSWORD_DB 
           FROM DEMO.DEMO_SECURITY 
           WHERE USERID = V_USERID_IN
           AND ACTIVE = 'Y';
           
        -- Convert Security Master Key into RAW
           SECURITY_MASTER_KEY_RAW := UTL_RAW.CAST_TO_RAW(CONVERT(SECURITY_MASTER_KEY,'AL32UTF8','US7ASCII'));
           
        -- Convert User Supplied Password To Raw    
           RAW_PASSWORD_IN := UTL_RAW.CAST_TO_RAW(CONVERT(V_PASSWORD_IN,'AL32UTF8','US7ASCII'));
 
        -- Encrypt User Supplied Password - Add MAC  
           ENCRYPTED_PSW := DBMS_CRYPTO.MAC(SRC => RAW_PASSWORD_IN,  TYP => DBMS_CRYPTO.HMAC_MD5, KEY => SECURITY_MASTER_KEY_RAW);

        -- Print out encrypted passwords for comparison - Comment this out when you are satisfied that the code works!
           dbms_output.put_line ('V_PASSWORD_DB='||V_PASSWORD_DB);
           dbms_output.put_line ('ENCRYPTED_PSW='||ENCRYPTED_PSW);
                  
        -- Compare User Supplied Password to the one stored in the Database for the same User
           IF  (ENCRYPTED_PSW = V_PASSWORD_DB) THEN
                  dbms_output.put_line ('MATCH');
                  RETURN('Y');
           ELSE
                  dbms_output.put_line ('NO MATCH FOUND!');
                  RETURN('N');
           END IF;

    EXCEPTION
         WHEN USER_DO_NOT_EXIST THEN
         
            RAISE_APPLICATION_ERROR(-20104,'User Does Not Exist');     
            RETURN(NULL);
            
         WHEN OTHERS THEN
          --load error variables
            V_PROCSTEP := DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
            V_ERRORMSG := SUBSTR(SQLERRM,1,200);
            V_ERRCODE  := sqlcode;

          --log error message
            DEMO_UTILITIES_PKG.DEMOLOG_ERROR_MSG(C_PROCNAME, V_PROCSTEP, USER,V_ERRORMSG, V_ERRCODE);

          --Raise Application Error
            RAISE_APPLICATION_ERROR(-20103,C_PROCNAME||':  '||V_ERRORMSG||':  '||V_ERRCODE);           
    END VERIFY_USER;
    
END;
/

--If package did not compile correctly the first time
--ALTER PACKAGE "DEMO"."DEMO_SECURITY_PKG" COMPILE;
--/


--Give Grants to ROLE DB_WEB_USER
@C:/oracle/DBMS_CRYPTO_DEMO/WEB_USER_ROLE.sql;

-- GRANT ROLE TO USER WEB_APPLICATION
GRANT DB_WEB_USER TO "WEB_APPLICATION";

DECLARE
  V_USERID_IN VARCHAR2(200);
  V_PASSWORD_IN VARCHAR2(200);
  v_Return VARCHAR2(200);
BEGIN
  V_USERID_IN := 'DEMO';
  V_PASSWORD_IN := 'DEMO$1';

  v_Return := DEMO.DEMO_SECURITY_PKG.CREATE_UPDATE_USER(
    V_USERID_IN => V_USERID_IN,
    V_PASSWORD_IN => V_PASSWORD_IN
  );
-- Legacy output: 
DBMS_OUTPUT.PUT_LINE('CREATE_UPDATE_USER = ' || v_Return);
END;
/