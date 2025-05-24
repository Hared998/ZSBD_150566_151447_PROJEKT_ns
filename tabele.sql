
CREATE SEQUENCE SEQ_PROGNOZY START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_LOGI START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE SEQ_RAPORTY START WITH 1 INCREMENT BY 1;

CREATE TABLE Lokalizacje (
    id_lokalizacji NUMBER PRIMARY KEY,
    nazwa VARCHAR2(100),
    szerokosc NUMBER,
    dlugosc NUMBER,
    kraj VARCHAR2(100)
);

CREATE TABLE Warunki (
    id_warunku NUMBER PRIMARY KEY,
    nazwa VARCHAR2(100)
);

CREATE TABLE Prognozy (
    id_prognozy NUMBER PRIMARY KEY,
    id_lokalizacji NUMBER REFERENCES Lokalizacje(id_lokalizacji),
    data_prognozy DATE,
    temperatura NUMBER,
    wilgotnosc NUMBER,
    cisnienie NUMBER,
    wiatr_km_h NUMBER,
    id_warunku NUMBER REFERENCES Warunki(id_warunku),
    ekstremum VARCHAR2(1)
);

CREATE TABLE Archiwum_Prognoz AS SELECT * FROM Prognozy WHERE 1=0;

CREATE TABLE Logi (
    id_logu NUMBER PRIMARY KEY,
    typ_operacji VARCHAR2(20),
    data_operacji TIMESTAMP,
    uzytkownik VARCHAR2(30),
    opis VARCHAR2(200)
);

CREATE TABLE Raport_Miesieczny (
    id_raportu NUMBER PRIMARY KEY,
    id_lokalizacji NUMBER,
    miesiac VARCHAR2(7),
    srednia_temperatura NUMBER,
    srednia_wilgotnosc NUMBER
);
