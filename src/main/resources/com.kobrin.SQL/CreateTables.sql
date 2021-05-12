/**
 * Author:  David Kobrin
 * Created: May 14, 2020
 */
-- CONNECT TO DATABASE
--CONNECT 'jdbc:derby://localhost:1527/%DERBY_DB_HOME%/FuelEcoService;create=true;user=DMK;password=pDaMsKs';

AUTOCOMMIT OFF;

--------------------------------------------------------
-- REMOVE SCHEMA IF THEY EXIST
--IF EXISTS VEHICLE_FUEL_TABLE THEN 
--DROP TABLE VEHICLE_FUEL_TABLE;
--IF EXISTS VEHICLE_SERVICE THEN
--DROP TABLE VEHICLE_SERVICE;
--IF EXISTS USER_VEHICLE THEN
--DROP TABLE USER_VEHICLE;
--IF EXISTS FUEL_EVENT THEN
DROP TABLE FUEL_EVENT;
--IF EXISTS SERVICE_TABLE THEN
DROP TABLE SERVICE_TABLE;
--IF EXISTS SERVICE_EVENT THEN
DROP TABLE SERVICE_EVENT;
--IF EXISTS VEHICLE_TABLE THEN
DROP TABLE VEHICLE_TABLE;
--IF EXISTS USER_TABLE THEN
DROP TABLE USER_TABLE;
--IF EXISTS NEW_VEHICLE_FUEL_EVENT THEN
DROP TRIGGER NEW_VEHICLE_FUEL_EVENT;

-----------------------------------------------------------
-- TABLE TO HOLD USER ACCOUNT DATA
CREATE TABLE USER_TABLE (
    USER_ID VARCHAR(20) NOT NULL,
    USER_PASS VARCHAR(20) NOT NULL,
    USER_TYPE VARCHAR(10) DEFAULT 'normal',
    FIRST_NAME VARCHAR(30),
    LAST_NAME VARCHAR(30)
);

ALTER TABLE USER_TABLE
    ADD CONSTRAINT USER_ID_PK PRIMARY KEY(USER_ID);

--------------------------------------------------------
-- TABLE TO HOLD VEHICLE SPECIFIC DATA
CREATE TABLE VEHICLE_TABLE (
    VIN CHAR(17) UNIQUE NOT NULL,
    MODEL_YEAR SMALLINT NOT NULL,
    MAKER VARCHAR(20) NOT NULL,
    MODEL_NAME VARCHAR(20) NOT NULL,
    TRIM_LEVEL VARCHAR(8) DEFAULT 'BASE',
    CURRENT_ODO INTEGER NOT NULL,
    TIRE_SIZE CHAR(9),
    DISPLAY_NAME VARCHAR(50) NOT NULL,
    IS_ACTIVE BOOLEAN NOT NULL DEFAULT TRUE,
    USER_ID VARCHAR(20) NOT NULL
);

ALTER TABLE VEHICLE_TABLE
    ADD CONSTRAINT USER_ID_FK FOREIGN KEY (USER_ID)
    REFERENCES USER_TABLE (USER_ID);

ALTER TABLE VEHICLE_TABLE
    ADD CONSTRAINT USER_VIN_PK PRIMARY KEY (USER_ID,VIN);

----------------------------------------------------------
-- TABLE TO HOLD RE-FUELING EVENT DATA
CREATE TABLE FUEL_EVENT (
    VIN CHAR(17) NOT NULL,
    EVENT_TIME TIMESTAMP NOT NULL,
    ODOMETER INTEGER NOT NULL,
    TOTAL_PRICE REAL NOT NULL,
    NUM_GAL REAL NOT NULL,
    IS_FULL_TANK BOOLEAN NOT NULL DEFAULT TRUE
);
ALTER TABLE FUEL_EVENT
    ADD CONSTRAINT VIN_FUEL_FK FOREIGN KEY (VIN) REFERENCES VEHICLE_TABLE (VIN);

ALTER TABLE FUEL_EVENT
    ADD CONSTRAINT EVENT_TIME_PK PRIMARY KEY (VIN, EVENT_TIME);

------------------------------------------------------------
-- TABLE TO HOLD SERVICE EVENT DATA
CREATE TABLE SERVICE_EVENT (
    SERV_EVENT_ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    ODOMETER INTEGER NOT NULL,
    SERV_DATE DATE NOT NULL,
    SERV_LOCATION VARCHAR(50),
    VIN CHAR(17) NOT NULL
);

ALTER TABLE SERVICE_EVENT
    ADD CONSTRAINT VIN_SERV_FK FOREIGN KEY (VIN) REFERENCES VEHICLE_TABLE (VIN);

ALTER TABLE SERVICE_EVENT
    ADD CONSTRAINT SERV_EVENT_ID_PK PRIMARY KEY (SERV_EVENT_ID);

------------------------------------------------------------
-- TABLE TO HOLD SERVICES PERFORMED IN A SERVICE EVENT
CREATE TABLE SERVICE_TABLE (
    SERV_ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY,
    SERV_DESC VARCHAR(50) NOT NULL,
    SERV_COST REAL NOT NULL DEFAULT 0.0,
    SERV_EVENT_ID INTEGER NOT NULL
);

ALTER TABLE SERVICE_TABLE
    ADD CONSTRAINT SERV_EVENT_ID_FK FOREIGN KEY (SERV_EVENT_ID) REFERENCES SERVICE_EVENT (SERV_EVENT_ID);

ALTER TABLE SERVICE_TABLE
    ADD CONSTRAINT SERV_ID_PK PRIMARY KEY (SERV_ID);




-----------------------------------------------------------
-- LINK VEHICLE_TABLE AND FUEL_EVENT
--CREATE TABLE VEHICLE_FUEL_TABLE (
--    VIN CHAR(17) NOT NULL,
--    EVENT_TIME TIMESTAMP NOT NULL
--);

--ALTER TABLE VEHICLE_FUEL_TABLE
--    ADD CONSTRAINT VIN_FK
--    FOREIGN KEY (VIN) REFERENCES VEHICLE_TABLE (VIN);

--ALTER TABLE VEHICLE_FUEL_TABLE
--    ADD CONSTRAINT EVENT_TIME_FK
--    FOREIGN KEY (EVENT_TIME) REFERENCES FUEL_EVENT (EVENT_TIME);


-----------------------------------------------------------
-- LINK SERVICE_TABLE TO VEHICLE_TABLE
--CREATE TABLE VEHICLE_SERVICE (
--    VIN CHAR(17) NOT NULL,
--    SERV_EVENT_ID INTEGER NOT NULL
--);

--ALTER TABLE VEHICLE_SERVICE
--    ADD CONSTRAINT VIN_FK
--    FOREIGN KEY (VIN) REFERENCES VEHICLE_TABLE (VIN);

--ALTER TABLE VEHICLE_SERVICE
--    ADD CONSTRAINT SERV_EVENT_ID_FK
--    FOREIGN KEY (SERV_EVENT_ID) REFERENCES SERVICE_TABLE (SERV_EVENT_ID);
--);


------------------------------------------------------------
-- LINK USER_TABLE TO VEHICLE_TABLE
--CREATE TABLE USER_VEHICLE (
--    USER_ID VARCHAR(20) NOT NULL,
--    VIN CHAR(17) NOT NULL
--);

--ALTER TABLE USER_VEHICLE
--    ADD CONSTRAINT USER_ID_FK
--    FOREIGN KEY (USER_ID) REFERENCES USER_TABLE (USER_ID);

--ALTER TABLE USER_VEHICLE
--    ADD CONSTRAINT VIN_FK
--    FOREIGN KEY (VIN) REFERENCES VEHICLE_TABLE (VIN);

------------------------------------------------------------

-- CREATE DATA MANAGEMENT TRIGGER EVENTS

-- WHEN ADDING A NEW FUEL_EVENT
-- CHECK TO MAKE SURE THAT THE FIELD VEHICLE_TABLE.CURRENT_ODO HAS THE CORRECT
-- VALUE (IE. THE HIGHEST MILEAGE FROM THE FUEL_EVENT TABLE FOR THAT VEHICLE)
CREATE TRIGGER NEW_VEHICLE_FUEL_EVENT AFTER INSERT ON FUEL_EVENT
    REFERENCING NEW AS N
    FOR EACH ROW MODE DB2SQL
        WHEN (N.ODOMETER > (SELECT CURRENT_ODO FROM VEHICLE_TABLE WHERE (VIN = N.VIN)))
        UPDATE VEHICLE_TABLE SET CURRENT_ODO = N.ODOMETER WHERE (VIN = N.VIN);
         
------------------------------------------------------------
COMMIT;
AUTOCOMMIT ON;
