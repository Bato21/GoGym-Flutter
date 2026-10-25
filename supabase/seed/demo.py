"""Puebla la cuenta demo (demo@gogym.app) con perfil, rutinas y 2 semanas de sesiones.

Uso, desde la raíz del proyecto (lee env.json):
    python supabase/seed/demo.py

La cuenta debe existir (se crea desde la app con "Crear cuenta"). Es idempotente:
borra las rutinas y sesiones de la cuenta antes de insertar. Las fechas son
relativas al día en que se corre, así que conviene correrlo el día de la demo
para que la racha siga viva.
"""
import json, random, sys, urllib.request, urllib.error
from datetime import datetime, timedelta, date

env = json.load(open("env.json"))
U, K = env["SUPABASE_URL"], env["SUPABASE_PUBLISHABLE_KEY"]
EMAIL, PASS = "demo@gogym.app", "demo2026"


def req(method, path, body=None, token=None, prefer=None):
    h = {"apikey": K, "Content-Type": "application/json"}
    if token:
        h["Authorization"] = "Bearer " + token
    if prefer:
        h["Prefer"] = prefer
    data = None if body is None else json.dumps(body).encode()
    r = urllib.request.Request(U + path, method=method, headers=h, data=data)
    try:
        raw = urllib.request.urlopen(r).read()
        return json.loads(raw) if raw else None
    except urllib.error.HTTPError as ex:
        raise SystemExit(f"{method} {path} -> HTTP {ex.code}: {ex.read().decode()[:600]}")


auth = req("POST", "/auth/v1/token?grant_type=password", {"email": EMAIL, "password": PASS})
tok, uid = auth["access_token"], auth["user"]["id"]
cat = {c["id"]: c for c in req("GET", "/rest/v1/ejercicios?select=id,nombre,grupo,met,imagen", token=tok)}

# --- Rutinas -----------------------------------------------------------------
# (catalogoId, series, reps, carga_kg | None, descanso, carga_texto_si_no_kg)
RUTINAS = [
    ("Push A", "Fuerza", "Intermedio", 55, [
        ("bench-press", 4, 8, 60, 120, None),
        ("incline-db-press", 3, 10, 22, 90, None),
        ("ohp", 3, 8, 37.5, 90, None),
        ("lateral-raise", 4, 12, 8, 60, None),
        ("tricep-pushdown", 3, 12, 25, 60, None),
    ]),
    ("Pull A", "Fuerza", "Intermedio", 50, [
        ("deadlift", 3, 5, 100, 150, None),
        ("lat-pulldown", 4, 10, 55, 90, None),
        ("barbell-row", 3, 8, 50, 90, None),
        ("face-pull", 3, 15, 20, 60, None),
        ("barbell-curl", 3, 10, 25, 60, None),
    ]),
    ("Legs A", "Fuerza", "Avanzado", 60, [
        ("squat", 5, 5, 80, 150, None),
        ("romanian-deadlift", 4, 8, 60, 120, None),
        ("leg-press", 3, 12, 140, 90, None),
        ("leg-curl", 3, 12, 35, 60, None),
        ("machine-calf-raise", 4, 15, 50, 45, None),
    ]),
    ("Core y cardio", "Cardio", "Principiante", 35, [
        ("jump-rope", 4, 0, None, 45, "90 s"),
        ("plank", 3, 0, None, 45, "60 s"),
        ("bicycle-crunch", 3, 20, None, 45, "Peso corporal"),
        ("hanging-leg-raise", 3, 12, None, 60, "Peso corporal"),
    ]),
]


def ej_rutina(i, cid, series, reps, kg, desc, texto):
    c = cat[cid]
    return {
        "id": 1000 + i, "nombre": c["nombre"], "grupo": c["grupo"],
        "series": series, "repeticiones": reps,
        "carga": f"{kg:g} kg" if kg is not None else texto,
        "descansoSeg": desc, "catalogoId": cid, "imagen": c["imagen"], "met": float(c["met"]),
    }


req("DELETE", f"/rest/v1/sesiones?user_id=eq.{uid}", token=tok)
req("PATCH", f"/rest/v1/perfiles?id=eq.{uid}", {"rutina_favorita_id": None}, token=tok)
req("DELETE", f"/rest/v1/rutinas?user_id=eq.{uid}", token=tok)

filas = []
hoy = date.today()
base_id = int(datetime(hoy.year, hoy.month, hoy.day, 12, tzinfo=datetime.now().astimezone().tzinfo).timestamp() * 1000)
for r_i, (nombre, categoria, nivel, minutos, ejs) in enumerate(RUTINAS):
    filas.append({
        "id": base_id + len(RUTINAS) - 1 - r_i, "user_id": uid, "nombre": nombre, "categoria": categoria, "nivel": nivel, "minutos": minutos,
        "ejercicios": [ej_rutina(r_i * 10 + i, *e) for i, e in enumerate(ejs)],
    })
creadas = []
for f in filas:  # una por una para que los id queden en orden de rotación
    creadas += req("POST", "/rest/v1/rutinas", f, token=tok, prefer="return=representation")
print("rutinas:", [(r["id"], r["nombre"]) for r in creadas])

# --- Perfil --------------------------------------------------------------------
perfil = {
    "id": uid, "nombre": "Vicente", "apellido": "Rodríguez",
    "objetivo": "Ganar masa muscular", "peso_kg": 78,
    "dias_entrenamiento": [0, 1, 2, 3, 4, 5], "hora_entrenamiento": "18:00",
    "meta_calorias": 2400, "rutina_favorita_id": creadas[0]["id"],
}
req("POST", "/rest/v1/perfiles", perfil, token=tok, prefer="resolution=merge-duplicates,return=minimal")

# --- Sesiones ------------------------------------------------------------------
# 12 entrenamientos relativos a hoy: 4 seguidos, un descanso y los últimos 8 días
# seguidos hasta ayer. Hoy queda libre: la racha de 8 sigue viva y se puede
# empezar un entrenamiento en vivo. Correr de nuevo el día de la demo.
dias = [hoy - timedelta(days=d) for d in (13, 12, 11, 10, 8, 7, 6, 5, 4, 3, 2, 1)]
tz = datetime.now().astimezone().tzinfo
rnd = random.Random(2026)
sesiones = []
for n, dia in enumerate(dias):
    ciclo = n // len(RUTINAS)  # 0, 1, 2: sube la carga en cada vuelta
    r_i = n % len(RUTINAS)
    nombre, _, _, minutos, ejs = RUTINAS[r_i]
    inicio = datetime(dia.year, dia.month, dia.day, 18, rnd.randint(0, 25), tzinfo=tz)
    fin = inicio + timedelta(minutes=minutos + rnd.randint(-6, 8))
    ejercicios = []
    for i, (cid, series, reps, kg, _, _) in enumerate(ejs):
        c = cat[cid]
        lista = []
        for s in range(series):
            if kg is None:
                lista.append({"kg": None, "reps": reps or None, "rpe": rnd.randint(6, 8)})
                continue
            paso = 5 if kg >= 50 else 2.5 if kg >= 20 else 1
            peso = kg + paso * ciclo
            hechas = reps - (1 if s == series - 1 and rnd.random() < 0.4 else 0)
            lista.append({"kg": peso, "reps": hechas, "rpe": min(10, 7 + s // 2 + rnd.randint(0, 1))})
        ejercicios.append({
            "id": int(inicio.timestamp()) * 10 + i, "catalogoId": cid, "nombre": c["nombre"],
            "grupo": c["grupo"], "imagen": c["imagen"], "met": float(c["met"]),
            "repsObjetivo": reps or None, "series": lista,
        })
    sesiones.append({
        "id": int(fin.timestamp() * 1000), "user_id": uid, "nombre": nombre, "rutina_id": creadas[r_i]["id"],
        "inicio": inicio.isoformat(), "fin": fin.isoformat(), "ejercicios": ejercicios,
    })
req("POST", "/rest/v1/sesiones", sesiones, token=tok, prefer="return=minimal")

check = req("GET", f"/rest/v1/sesiones?select=nombre,inicio&user_id=eq.{uid}&order=inicio", token=tok)
print("sesiones:", len(check))
for s in check:
    print(" ", s["inicio"], s["nombre"])
