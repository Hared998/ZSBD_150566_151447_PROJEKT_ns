
CREATE OR REPLACE PROCEDURE DodajPrognoze (
    p_id_lokalizacji NUMBER,
    p_data DATE,
    p_temp NUMBER,
    p_wilg NUMBER,
    p_cisnienie NUMBER,
    p_wiatr NUMBER,
    p_id_warunku NUMBER
) AS
BEGIN
    IF p_temp < -100 OR p_temp > 60 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Nieprawidłowa temperatura');
    END IF;

    IF p_wilg < 0 OR p_wilg > 100 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Nieprawidłowa wilgotność');
    END IF;

    INSERT INTO Prognozy (
        id_prognozy, id_lokalizacji, data_prognozy,
        temperatura, wilgotnosc, cisnienie, wiatr_km_h, id_warunku
    ) VALUES (
        SEQ_PROGNOZY.NEXTVAL, p_id_lokalizacji, p_data,
        p_temp, p_wilg, p_cisnienie, p_wiatr, p_id_warunku
    );

    INSERT INTO Logi VALUES (
        SEQ_LOGI.NEXTVAL, 'DODANIE', SYSTIMESTAMP, USER,
        'Dodano prognozę dla lokalizacji ' || p_id_lokalizacji
    );
END;
/

CREATE OR REPLACE PROCEDURE PrzywrocPrognoze (
    p_id_prognozy NUMBER
) AS
    v_lokalizacja NUMBER;
    v_data DATE;
    v_temperatura NUMBER;
    v_wilgotnosc NUMBER;
    v_cisnienie NUMBER;
    v_wiatr NUMBER;
    v_id_warunku NUMBER;
    v_ekstremum VARCHAR2(1);
BEGIN
    SELECT id_lokalizacji, data_prognozy, temperatura, wilgotnosc,
           cisnienie, wiatr_km_h, id_warunku, ekstremum
    INTO v_lokalizacja, v_data, v_temperatura, v_wilgotnosc,
         v_cisnienie, v_wiatr, v_id_warunku, v_ekstremum
    FROM Archiwum_Prognoz
    WHERE id_prognozy = p_id_prognozy;

    -- Wstaw do Prognozy przez DodajPrognoze
    DodajPrognoze(
        v_lokalizacja,
        v_data,
        v_temperatura,
        v_wilgotnosc,
        v_cisnienie,
        v_wiatr,
        v_id_warunku
    );

    -- Usuń z archiwum
    DELETE FROM Archiwum_Prognoz WHERE id_prognozy = p_id_prognozy;

    -- Log przywrócenia
    INSERT INTO Logi (
        id_logu, typ_operacji, data_operacji, uzytkownik, opis
    ) VALUES (
        SEQ_LOGI.NEXTVAL, 'PRZYWRÓCENIE', SYSTIMESTAMP, USER,
        'Przywrócono prognozę z Archiwum o ID ' || p_id_prognozy
    );
END;
/

CREATE OR REPLACE PROCEDURE GenerujRaportMiesieczny(
    p_rok NUMBER,
    p_miesiac NUMBER
) AS
BEGIN
    FOR rec IN (
        SELECT id_lokalizacji,
               TO_CHAR(DATE '2025-01-01' + (p_miesiac - 1) * INTERVAL '1' MONTH, 'YYYY-MM') AS miesiac,
               ROUND(AVG(temperatura), 2) AS srednia_temperatura,
               ROUND(AVG(wilgotnosc), 2) AS srednia_wilgotnosc
        FROM Prognozy
        WHERE EXTRACT(YEAR FROM data_prognozy) = p_rok
          AND EXTRACT(MONTH FROM data_prognozy) = p_miesiac
        GROUP BY id_lokalizacji
    ) LOOP
        INSERT INTO Raport_Miesieczny (
            id_raportu, id_lokalizacji, miesiac, srednia_temperatura, srednia_wilgotnosc
        ) VALUES (
            SEQ_RAPORTY.NEXTVAL, rec.id_lokalizacji, rec.miesiac, rec.srednia_temperatura, rec.srednia_wilgotnosc
        );
    END LOOP;
END;
/
