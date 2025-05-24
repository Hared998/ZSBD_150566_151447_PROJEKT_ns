import requests
from datetime import datetime

API_KEY = '394fca4172261af4dee8b6595ac7f0cb'

miasta = [
    {"id": 1, "nazwa": "Warszawa", "lat": 52.2297, "lon": 21.0122, "kraj": "Polska"},
    {"id": 2, "nazwa": "Kraków", "lat": 50.0647, "lon": 19.9450, "kraj": "Polska"},
    {"id": 3, "nazwa": "Gdańsk", "lat": 54.3520, "lon": 18.6466, "kraj": "Polska"},
    {"id": 4, "nazwa": "Olsztyn", "lat": 53.7784, "lon": 20.4801, "kraj": "Polska"}
]
warunki_dodane = set() 

with open('prognozy_exec.sql', 'w', encoding='utf-8') as file:
    for miasto in miasta:
        print(f"Pobieram dane dla: {miasto['nazwa']}...")

        url = (
            f"https://api.openweathermap.org/data/2.5/weather?"
            f"lat={miasto['lat']}&lon={miasto['lon']}"
            f"&appid={API_KEY}&units=metric&lang=pl"
        )

        response = requests.get(url)
        data = response.json()

        if response.status_code != 200 or "main" not in data:
            print(f'Błąd przy {miasto["nazwa"]}: {data}')
            continue

        file.write(f"""
-- Dodanie miasta {miasto['nazwa']} (jeśli nie istnieje)
INSERT INTO Lokalizacje (id_lokalizacji, nazwa, szerokosc, dlugosc, kraj)
SELECT {miasto['id']}, '{miasto['nazwa']}', {miasto['lat']}, {miasto['lon']}, '{miasto['kraj']}'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM Lokalizacje WHERE id_lokalizacji = {miasto['id']}
);
""")

        id_warunku = data['weather'][0]['id']
        opis_warunku = data['weather'][0]['description'].capitalize()

        if id_warunku not in warunki_dodane:
            file.write(f"""
-- Dodanie warunku {opis_warunku} (jeśli nie istnieje)
INSERT INTO Warunki (id_warunku, nazwa)
SELECT {id_warunku}, '{opis_warunku}'
FROM DUAL
WHERE NOT EXISTS (
    SELECT 1 FROM Warunki WHERE id_warunku = {id_warunku}
);
""")
            warunki_dodane.add(id_warunku)

        data_prognozy = datetime.utcfromtimestamp(data['dt']).strftime('%Y-%m-%d %H:%M:%S')
        temperatura = data['main']['temp']
        wilgotnosc = data['main']['humidity']
        cisnienie = data['main']['pressure']
        wiatr_km_h = round(data['wind']['speed'] * 3.6, 2)

        file.write(f"""
-- Dodanie prognozy dla {miasto['nazwa']}
BEGIN
    DodajPrognoze(
        {miasto["id"]},
        TO_DATE('{data_prognozy}', 'YYYY-MM-DD HH24:MI:SS'),
        {temperatura}, {wilgotnosc}, {cisnienie}, {wiatr_km_h}, {id_warunku}
    );
END;
/
""")

print("Plik 'prognozy_exec.sql' został utworzony.")