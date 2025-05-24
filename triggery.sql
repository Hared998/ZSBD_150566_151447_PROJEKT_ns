
CREATE OR REPLACE TRIGGER OZNACZ_EKSTREMUM
BEFORE INSERT OR UPDATE ON Prognozy
FOR EACH ROW
BEGIN
    IF :NEW.temperatura > 30 THEN
        :NEW.ekstremum := 'U'; -- Upał
    ELSIF :NEW.temperatura < -5 THEN
        :NEW.ekstremum := 'M'; -- Mróz
    ELSIF :NEW.wiatr_km_h > 70 THEN
        :NEW.ekstremum := 'W'; -- Wiatr
    ELSE
        :NEW.ekstremum := '-'; -- Brak ekstremum
    END IF;
END;
/

CREATE OR REPLACE TRIGGER LOG_USUN_PROGNOZE
BEFORE DELETE ON Prognozy
FOR EACH ROW
BEGIN
    INSERT INTO Archiwum_Prognoz VALUES (
        :OLD.id_prognozy, :OLD.id_lokalizacji, :OLD.data_prognozy,
        :OLD.temperatura, :OLD.wilgotnosc, :OLD.cisnienie,
        :OLD.wiatr_km_h, :OLD.id_warunku, :OLD.ekstremum
    );

    INSERT INTO Logi (
        id_logu, typ_operacji, data_operacji, uzytkownik, opis
    ) VALUES (
        SEQ_LOGI.NEXTVAL, 'USUNIECIE', SYSTIMESTAMP, USER,
        'Usunięto prognozę ID ' || :OLD.id_prognozy
    );
END;
/
