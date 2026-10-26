"""Minimarket ALTES - Sistema web local (SQLite, 15 tablas).  Uso:  python app.py"""
import sqlite3, json, os, re, time, hashlib, hmac, secrets, webbrowser
from http.cookies import SimpleCookie
from pathlib import Path
from datetime import datetime, timedelta
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

D = os.path.dirname(os.path.abspath(__file__))
DB, SQL = os.path.join(D, "minimarket_altes.db"), os.path.join(D, "minimarket_altes_sqlite.sql")
NEGOCIO = {"nombre": "MINIMARKET ALTES", "ruc": "20XXXXXXXXX", "direccion": "Lima, Perú", "telefono": ""}  # <- editar
IGV, SERIE = 0.18, {"boleta": "B001", "factura": "F001"}
now = lambda: datetime.now().strftime("%Y-%m-%d %H:%M:%S")
DEFAULT_PW = "altes2026"  # contraseña inicial de los usuarios (cada uno debe cambiarla desde el sistema)
SECCIONES = {"administrador": ["dash", "venta", "productos", "ingreso", "clientes", "proveedores", "empleados", "hist", "sql"],
             "cajero": ["dash", "venta", "clientes", "hist"], "almacenero": ["dash", "productos", "ingreso", "proveedores"]}
# recurso: (roles que pueden LEER, roles que pueden ESCRIBIR). El administrador puede todo; lo que no figura aquí es solo de administrador.
ACCESS = {"productos": ({"cajero", "almacenero"}, {"almacenero"}), "categorias": ({"cajero", "almacenero"}, set()),
          "clientes": ({"cajero"}, {"cajero"}), "proveedores": ({"almacenero"}, {"almacenero"}), "caja": ({"cajero"}, {"cajero"}),
          "ventas": ({"cajero"}, {"cajero"}), "compras": ({"almacenero"}, {"almacenero"}), "dashboard": ({"cajero", "almacenero"}, set())}
SESSIONS, FALLOS = {}, {}

def hpw(p, salt=None):
    salt = salt or secrets.token_hex(8)
    return f"pbkdf2${salt}${hashlib.pbkdf2_hmac('sha256', p.encode(), salt.encode(), 100_000).hex()}"
def chk(p, stored):
    try: return hmac.compare_digest(hpw(p, stored.split("$")[1]), stored)
    except Exception: return False
def permitido(rol, ruta, escribir):
    return rol == "administrador" or rol in ACCESS.get(ruta.split("/")[0], (set(), set()))[1 if escribir else 0]
# stock restante de un lote = suma de sus movimientos (ingreso/ajuste suman; salida/merma restan)
REST = "COALESCE(SUM(CASE m.tipo_movimiento WHEN 'ingreso' THEN m.cantidad WHEN 'ajuste' THEN m.cantidad ELSE -m.cantidad END),0)"
NUM = "(SELECT COUNT(*) FROM Venta w WHERE w.tipo_comprobante=v.tipo_comprobante AND w.venta_id<=v.venta_id)"

class Err(Exception): pass

def db():
    c = sqlite3.connect(DB); c.row_factory = sqlite3.Row; c.execute("PRAGMA foreign_keys=ON"); return c

def init():
    if not os.path.exists(DB):  # crea la base desde tu código SQL
        c = sqlite3.connect(DB); c.executescript(open(SQL, encoding="utf-8").read()); c.commit(); c.close()
    c = sqlite3.connect(DB)  # migración: contrato del empleado (inicio + duración en meses)
    cols = {r[1] for r in c.execute("PRAGMA table_info(Empleado)")}
    for col, typ in (("contrato_inicio", "DATE"), ("contrato_meses", "INTEGER")):
        if col not in cols: c.execute(f"ALTER TABLE Empleado ADD COLUMN {col} {typ}")
    for uid, pw in c.execute("SELECT usuario_id, password FROM Usuario").fetchall():  # contraseñas de ejemplo -> hash real
        if not pw.startswith("pbkdf2$"): c.execute("UPDATE Usuario SET password=? WHERE usuario_id=?", (hpw(DEFAULT_PW), uid))
    c.commit(); c.close()

def rows(c, q, a=()): return [dict(r) for r in c.execute(q, a)]
def num(x, d=0.0):
    try: return float(x) if x not in (None, "") else d
    except ValueError: raise Err("Número inválido")
def txt(d, k): return (d.get(k) or "").strip() or None

def guardar(c, ent, d):
    i = d.get("id")
    try:
        if ent == "clientes":
            if not txt(d, "nombres"): raise Err("El nombre es obligatorio")
            doc = txt(d, "dni")
            if not doc or not re.fullmatch(r"\d{8}|\d{11}", doc): raise Err("Ingresa DNI (8 dígitos) o RUC (11 dígitos)")
            v = [txt(d, "nombres"), txt(d, "apellidos") or "-", doc, txt(d, "telefono"), txt(d, "direccion")]
            if i: c.execute("UPDATE Cliente SET nombres=?,apellidos=?,dni=?,telefono=?,direccion=? WHERE cliente_id=?", v + [i])
            else: c.execute("INSERT INTO Cliente(nombres,apellidos,dni,telefono,direccion,fecha_registro,estado) VALUES(?,?,?,?,?,date('now'),1)", v)
        elif ent == "empleados":
            doc, rol = txt(d, "dni"), d.get("cargo")
            if not txt(d, "nombres") or not txt(d, "apellidos"): raise Err("Nombres y apellidos son obligatorios")
            if not doc or not re.fullmatch(r"\d{8}", doc): raise Err("El DNI debe tener 8 dígitos")
            if rol not in ("administrador", "cajero", "almacenero"): raise Err("Selecciona el rol del empleado")
            try: meses = int(d.get("contrato_meses"))
            except (TypeError, ValueError): raise Err("Indica la duración del contrato")
            if not 3 <= meses <= 12: raise Err("La duración del contrato debe ser de 3 a 12 meses (máximo 1 año)")
            try: ini = datetime.strptime(d.get("contrato_inicio") or "", "%Y-%m-%d").strftime("%Y-%m-%d")
            except ValueError: raise Err("Fecha de inicio del contrato inválida")
            if i and int(i) == int(d.get("empleado_id") or 0) and rol != "administrador": raise Err("No puedes quitarte el rol de administrador a ti mismo")
            v = [txt(d, "nombres"), txt(d, "apellidos"), doc, rol, txt(d, "telefono"), ini, meses]
            if i:
                eid = int(i)
                c.execute("UPDATE Empleado SET nombres=?,apellidos=?,dni=?,cargo=?,telefono=?,contrato_inicio=?,contrato_meses=? WHERE empleado_id=?", v + [eid])
            else:
                eid = c.execute("INSERT INTO Empleado(nombres,apellidos,dni,cargo,telefono,fecha_ingreso,contrato_inicio,contrato_meses,estado) VALUES(?,?,?,?,?,?,?,?,1)", v[:5] + [ini, ini, meses]).lastrowid
            user, pw = (txt(d, "username") or "").lower(), d.get("password") or ""
            if user and not re.fullmatch(r"[a-z0-9_.]{3,30}", user): raise Err("Usuario: 3 a 30 caracteres (minúsculas, números, punto o _)")
            if pw and len(pw) < 6: raise Err("La contraseña debe tener al menos 6 caracteres")
            if c.execute("SELECT 1 FROM Usuario WHERE empleado_id=?", (eid,)).fetchone():
                if user: c.execute("UPDATE Usuario SET username=? WHERE empleado_id=?", (user, eid))
                if pw: c.execute("UPDATE Usuario SET password=? WHERE empleado_id=?", (hpw(pw), eid))
                c.execute("UPDATE Usuario SET rol=? WHERE empleado_id=?", (rol, eid))  # el rol del empleado define sus permisos
            elif not i or user or pw:
                if not user or not pw: raise Err("Indica el usuario y una contraseña de al menos 6 caracteres")
                c.execute("INSERT INTO Usuario(empleado_id,username,password,rol,estado,fecha_registro) VALUES(?,?,?,?,1,?)", (eid, user, hpw(pw), rol, now()))
        elif ent == "proveedores":
            if not txt(d, "razon_social") or not txt(d, "ruc"): raise Err("Razón social y RUC son obligatorios")
            v = [txt(d, k) for k in ("razon_social", "ruc", "telefono", "email", "direccion", "contacto")]
            if i: c.execute("UPDATE Proveedor SET razon_social=?,ruc=?,telefono=?,email=?,direccion=?,contacto=? WHERE proveedor_id=?", v + [i])
            else: c.execute("INSERT INTO Proveedor(razon_social,ruc,telefono,email,direccion,contacto,estado) VALUES(?,?,?,?,?,?,1)", v)
        elif ent == "productos":
            if not txt(d, "nombre") or not d.get("precio_venta"): raise Err("Nombre y precio de venta son obligatorios")
            cod = txt(d, "codigo_barras") or "INT" + datetime.now().strftime("%y%m%d%H%M%S")
            v = [int(d["categoria_id"]), cod, txt(d, "nombre"), txt(d, "unidad_medida") or "unidad", num(d.get("precio_compra")), num(d["precio_venta"])]
            iv = [num(d.get("stock_minimo"), 10), num(d.get("stock_maximo"), 100), txt(d, "ubicacion")]
            if i:
                c.execute("UPDATE Producto SET categoria_id=?,codigo_barras=?,nombre=?,unidad_medida=?,precio_compra=?,precio_venta=? WHERE producto_id=?", v + [i])
                c.execute("UPDATE Inventario SET stock_minimo=?,stock_maximo=?,ubicacion=? WHERE producto_id=?", iv + [i])
            else:
                pid = c.execute("INSERT INTO Producto(categoria_id,codigo_barras,nombre,unidad_medida,precio_compra,precio_venta,descripcion,estado) VALUES(?,?,?,?,?,?,?,1)", v + [v[2]]).lastrowid
                c.execute("INSERT INTO Inventario(producto_id,stock_actual,stock_minimo,stock_maximo,ubicacion,fecha_actualizacion) VALUES(?,0,?,?,?,?)", [pid] + iv + [now()])
    except sqlite3.IntegrityError:
        raise Err("Ya existe un registro con ese DNI/RUC, código de barras o usuario")

def check_emp(c, d):
    e = c.execute("SELECT empleado_id FROM Empleado WHERE empleado_id=? AND estado=1", (d.get("empleado_id"),)).fetchone()
    if not e: raise Err("Selecciona el empleado que atiende")
    return e[0]

def caja(c, d):
    if d.get("accion") == "abrir":
        if c.execute("SELECT 1 FROM Caja WHERE estado=1").fetchone(): raise Err("Ya hay una caja abierta")
        c.execute("INSERT INTO Caja(empleado_id,fecha_apertura,monto_apertura,estado) VALUES(?,?,?,1)", (check_emp(c, d), now(), num(d.get("monto"))))
    else:
        if c.execute("UPDATE Caja SET fecha_cierre=?,monto_cierre=?,estado=0 WHERE estado=1", (now(), num(d.get("monto")))).rowcount == 0:
            raise Err("No hay caja abierta (RN-06)")
    return {"ok": 1}

def vender(c, d):
    cj = c.execute("SELECT caja_id FROM Caja WHERE estado=1 ORDER BY caja_id DESC").fetchone()
    if not cj: raise Err("Primero abre la caja (RN-06)")
    emp = check_emp(c, d); tipo = d.get("tipo", "boleta"); cli = d.get("cliente_id") or None
    cliente = c.execute("SELECT * FROM Cliente WHERE cliente_id=?", (cli,)).fetchone() if cli else None
    if tipo == "factura" and not (cliente and len(cliente["dni"]) == 11): raise Err("Para factura el cliente debe tener RUC de 11 dígitos")
    want = {}
    for it in d.get("items") or []: want[int(it["producto_id"])] = want.get(int(it["producto_id"]), 0) + num(it["cantidad"])
    if not want: raise Err("Agrega al menos un producto")
    det, total = [], 0
    for pid, q in want.items():  # FEFO: primero el lote que vence antes (RN-02)
        p = c.execute("SELECT * FROM Producto WHERE producto_id=?", (pid,)).fetchone()
        if not p or p["estado"] != 1 or q <= 0: raise Err("Producto inactivo o cantidad inválida")
        lotes = rows(c, f"""SELECT l.lote_id, {REST} rest FROM Lote l LEFT JOIN Movimiento_Inventario m ON m.lote_id=l.lote_id
            WHERE l.producto_id=? AND l.estado=1 AND (l.fecha_vencimiento IS NULL OR l.fecha_vencimiento>=date('now'))
            GROUP BY l.lote_id HAVING rest>0 ORDER BY l.fecha_vencimiento IS NULL, l.fecha_vencimiento, l.lote_id""", (pid,))
        need = q
        for l in lotes:
            t = min(l["rest"], need)
            if t > 0: det.append((pid, l["lote_id"], t, p["precio_venta"], round(p["precio_venta"] * t, 2))); need -= t
            if need <= 0: break
        if need > 0: raise Err(f"Stock vendible insuficiente de «{p['nombre']}» (disponible: {q - need:g})")
    total = round(sum(x[4] for x in det), 2)
    if tipo == "boleta" and total >= 700 and not cliente: raise Err("Boletas desde S/ 700 requieren identificar al cliente")
    base = round(total / (1 + IGV), 2)
    vid = c.execute("INSERT INTO Venta(cliente_id,empleado_id,caja_id,fecha_venta,tipo_comprobante,subtotal,igv,total,estado) VALUES(?,?,?,?,?,?,?,?,1)",
        (cli, emp, cj[0], now(), tipo, base, round(total - base, 2), total)).lastrowid
    for pid, lid, q, pu, sub in det:
        c.execute("INSERT INTO Detalle_Venta(venta_id,producto_id,lote_id,cantidad,precio_unitario,descuento,subtotal) VALUES(?,?,?,?,?,0,?)", (vid, pid, lid, q, pu, sub))
        c.execute("INSERT INTO Movimiento_Inventario(producto_id,lote_id,empleado_id,tipo_movimiento,cantidad,fecha_movimiento,motivo) VALUES(?,?,?,'salida',?,?,?)", (pid, lid, emp, q, now(), f"Venta {vid}"))
        c.execute("UPDATE Inventario SET stock_actual=stock_actual-?,fecha_actualizacion=? WHERE producto_id=?", (q, now(), pid))
    c.execute("INSERT INTO Pago(venta_id,metodo_pago,monto,fecha_pago,referencia) VALUES(?,?,?,?,?)", (vid, d.get("metodo_pago", "efectivo"), total, now(), txt(d, "referencia")))
    return {"id": vid}

def comprar(c, d):
    emp = check_emp(c, d); items = d.get("items") or []
    if not d.get("proveedor_id"): raise Err("Selecciona el proveedor (RN-04)")
    if not items: raise Err("Agrega al menos un producto")
    cid = c.execute("INSERT INTO Compra(proveedor_id,empleado_id,fecha_compra,tipo_pago,total,estado) VALUES(?,?,?,?,0,1)",
        (d["proveedor_id"], emp, now(), d.get("tipo_pago", "contado"))).lastrowid
    total = 0
    for n, i in enumerate(items, 1):
        q, pu, ven = num(i["cantidad"]), num(i["precio_unitario"]), txt(i, "fecha_vencimiento")
        if q <= 0: raise Err("Cantidad inválida")
        if ven and ven <= datetime.now().strftime("%Y-%m-%d"): raise Err("El vencimiento debe ser posterior a hoy (RN-05)")
        lid = c.execute("INSERT INTO Lote(producto_id,numero_lote,fecha_ingreso,fecha_vencimiento,cantidad,estado) VALUES(?,?,date('now'),?,?,1)",
            (i["producto_id"], txt(i, "numero_lote") or f"C{cid}-{n}", ven, q)).lastrowid
        sub = round(q * pu, 2); total += sub
        c.execute("INSERT INTO Detalle_Compra(compra_id,producto_id,lote_id,cantidad,precio_unitario,subtotal) VALUES(?,?,?,?,?,?)", (cid, i["producto_id"], lid, q, pu, sub))
        c.execute("INSERT INTO Movimiento_Inventario(producto_id,lote_id,empleado_id,tipo_movimiento,cantidad,fecha_movimiento,motivo) VALUES(?,?,?,'ingreso',?,?,?)", (i["producto_id"], lid, emp, q, now(), f"Compra {cid}"))
        c.execute("UPDATE Inventario SET stock_actual=stock_actual+?,fecha_actualizacion=? WHERE producto_id=?", (q, now(), i["producto_id"]))
        c.execute("UPDATE Producto SET precio_compra=? WHERE producto_id=?", (pu, i["producto_id"]))
    c.execute("UPDATE Compra SET total=? WHERE compra_id=?", (round(total, 2), cid))
    return {"id": cid}

def sql_run(d):
    """Consola SQL: conexión de SOLO LECTURA (SQLite la protege: no puede modificar ni borrar datos)."""
    q = (d.get("sql") or "").strip().rstrip(";").strip()
    if not q: raise Err("Escribe una consulta")
    c = sqlite3.connect(Path(DB).as_uri() + "?mode=ro", uri=True); t = time.time()
    try:
        cur = c.execute(q); cols = [x[0] for x in cur.description] if cur.description else []; data = cur.fetchmany(1001)
    except sqlite3.Error as e:
        m = str(e); raise Err("La consola es de solo lectura: usa SELECT (no INSERT/UPDATE/DELETE)." if "readonly" in m else m)
    finally: c.close()
    if not cols: raise Err("Solo se permiten consultas de lectura (SELECT, PRAGMA table_info...)")
    return {"cols": cols, "rows": [list(r) for r in data[:1000]], "truncado": len(data) > 1000, "ms": round((time.time() - t) * 1000, 2)}

VT = f"v.*, v.venta_id id, CASE v.tipo_comprobante WHEN 'factura' THEN 'F001' ELSE 'B001' END serie, {NUM} numero"
def get(c, path):
    if path == "productos":
        return rows(c, """SELECT p.*, p.producto_id id, ca.nombre categoria, i.stock_actual stock, i.stock_minimo, i.stock_maximo, i.ubicacion
            FROM Producto p JOIN Categoria ca ON ca.categoria_id=p.categoria_id LEFT JOIN Inventario i ON i.producto_id=p.producto_id
            ORDER BY p.estado DESC, p.nombre""")
    if path == "clientes": return rows(c, "SELECT *, cliente_id id, TRIM(nombres||' '||CASE apellidos WHEN '-' THEN '' ELSE apellidos END) nombre FROM Cliente WHERE estado=1 ORDER BY nombres")
    if path == "proveedores": return rows(c, "SELECT *, proveedor_id id FROM Proveedor WHERE estado=1 ORDER BY razon_social")
    if path == "categorias": return rows(c, "SELECT categoria_id id, nombre FROM Categoria WHERE estado=1 ORDER BY nombre")
    if path == "empleados":
        out = rows(c, """SELECT e.*, e.empleado_id id, e.nombres||' '||e.apellidos nombre, us.username,
            CASE WHEN e.contrato_inicio IS NULL THEN NULL ELSE date(e.contrato_inicio,'+'||e.contrato_meses||' months') END contrato_fin
            FROM Empleado e LEFT JOIN Usuario us ON us.empleado_id=e.empleado_id ORDER BY e.estado DESC, e.nombres""")
        hoy, lim = datetime.now().strftime("%Y-%m-%d"), (datetime.now() + timedelta(days=30)).strftime("%Y-%m-%d")
        for r in out:
            f = r["contrato_fin"]
            r["contrato"] = f"{r['contrato_inicio']} → {f} ({r['contrato_meses']} meses)" if f else "—"
            r["contrato_estado"] = "Baja" if not r["estado"] else "Sin registrar" if not f else "Vencido" if f < hoy else "Por vencer" if f <= lim else "Vigente"
        return out
    if path == "tablas":
        return [{"nombre": r[0], "filas": c.execute(f'SELECT COUNT(*) FROM "{r[0]}"').fetchone()[0]}
                for r in c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name")]
    if path == "caja":
        r = rows(c, """SELECT cj.*, e.nombres||' '||e.apellidos empleado, (SELECT COALESCE(SUM(total),0) FROM Venta WHERE caja_id=cj.caja_id) ventas
            FROM Caja cj JOIN Empleado e ON e.empleado_id=cj.empleado_id WHERE cj.estado=1 ORDER BY caja_id DESC LIMIT 1""")
        return r[0] if r else None
    if path == "ventas":
        return rows(c, f"""SELECT {VT}, COALESCE(TRIM(cl.nombres||' '||CASE cl.apellidos WHEN '-' THEN '' ELSE cl.apellidos END),'Clientes varios') cliente,
            (SELECT metodo_pago FROM Pago WHERE venta_id=v.venta_id LIMIT 1) metodo_pago FROM Venta v LEFT JOIN Cliente cl ON cl.cliente_id=v.cliente_id
            WHERE v.estado=1 ORDER BY v.venta_id DESC LIMIT 200""")
    if path == "compras":
        return rows(c, """SELECT co.*, co.compra_id id, pr.razon_social proveedor, (SELECT COUNT(*) FROM Detalle_Compra WHERE compra_id=co.compra_id) items
            FROM Compra co JOIN Proveedor pr ON pr.proveedor_id=co.proveedor_id ORDER BY co.compra_id DESC LIMIT 100""")
    if path == "dashboard":
        k = c.execute("""SELECT COUNT(*) n, COALESCE(SUM(i.stock_actual*p.precio_venta),0) inv, COALESCE(SUM(i.stock_actual<=i.stock_minimo),0) crit
            FROM Producto p LEFT JOIN Inventario i ON i.producto_id=p.producto_id WHERE p.estado=1""").fetchone()
        v = c.execute("SELECT COUNT(*) n, COALESCE(SUM(total),0) t FROM Venta WHERE estado=1").fetchone()
        return {"productos": k["n"], "inventario": round(k["inv"], 2), "critico": k["crit"], "ventas_n": v["n"], "ventas_total": round(v["t"], 2),
            "top": rows(c, """SELECT p.nombre, SUM(d.cantidad) u FROM Detalle_Venta d JOIN Venta ve ON ve.venta_id=d.venta_id AND ve.estado=1
                JOIN Producto p ON p.producto_id=d.producto_id GROUP BY p.producto_id ORDER BY u DESC LIMIT 5"""),
            "cat": rows(c, """SELECT ca.nombre, COALESCE(SUM(i.stock_actual),0) stock FROM Categoria ca LEFT JOIN Producto p ON p.categoria_id=ca.categoria_id
                LEFT JOIN Inventario i ON i.producto_id=p.producto_id GROUP BY ca.categoria_id"""),
            "vencer": rows(c, f"""SELECT * FROM (SELECT p.nombre, l.numero_lote, l.fecha_vencimiento, (SELECT {REST} FROM Movimiento_Inventario m WHERE m.lote_id=l.lote_id) rest
                FROM Lote l JOIN Producto p ON p.producto_id=l.producto_id WHERE l.estado=1 AND l.fecha_vencimiento IS NOT NULL
                AND l.fecha_vencimiento<=date('now','+45 days')) WHERE rest>0 ORDER BY fecha_vencimiento LIMIT 6""".replace("FROM Movimiento_Inventario m WHERE", "FROM Movimiento_Inventario m WHERE")),
            "ultimas": get(c, "ventas")[:5]}
    m = re.fullmatch(r"ventas/(\d+)", path)
    if m:
        r = rows(c, f"SELECT {VT} FROM Venta v WHERE v.venta_id=?", (m[1],))
        if not r: raise Err("No existe")
        v = r[0]
        v["cliente"] = (rows(c, "SELECT *, TRIM(nombres||' '||CASE apellidos WHEN '-' THEN '' ELSE apellidos END) nombre FROM Cliente WHERE cliente_id=?", (v["cliente_id"],)) or [None])[0]
        v["items"] = rows(c, "SELECT d.*, p.nombre FROM Detalle_Venta d JOIN Producto p ON p.producto_id=d.producto_id WHERE venta_id=?", (m[1],))
        v["metodo_pago"] = (c.execute("SELECT metodo_pago FROM Pago WHERE venta_id=?", (m[1],)).fetchone() or ["-"])[0]
        v["negocio"] = NEGOCIO
        return v
    raise Err("Ruta no encontrada")

def login(c, d):
    u, p = (d.get("username") or "").strip().lower(), d.get("password") or ""
    n, hasta = FALLOS.get(u, (0, 0))
    if hasta > time.time(): raise Err("Demasiados intentos fallidos. Espera 1 minuto.")
    r = c.execute("SELECT u.usuario_id, u.password FROM Usuario u JOIN Empleado e ON e.empleado_id=u.empleado_id WHERE lower(u.username)=? AND u.estado=1 AND e.estado=1", (u,)).fetchone()
    if not r or not chk(p, r["password"]):
        FALLOS[u] = (n + 1, time.time() + 60 if n + 1 >= 5 else 0); raise Err("Usuario o contraseña incorrectos")
    FALLOS.pop(u, None); tok = secrets.token_hex(24); SESSIONS[tok] = r["usuario_id"]; return tok

def quien(c, tok):
    uid = SESSIONS.get(tok)
    r = uid and c.execute("""SELECT u.usuario_id, u.rol, u.password, e.empleado_id, e.nombres||' '||e.apellidos nombre FROM Usuario u
        JOIN Empleado e ON e.empleado_id=u.empleado_id WHERE u.usuario_id=? AND u.estado=1 AND e.estado=1""", (uid,)).fetchone()
    return dict(r) if r else None

def perfil(u):
    lee = ["productos", "clientes", "proveedores", "categorias", "empleados"] if u["rol"] == "administrador" else [k for k, (rd, _) in ACCESS.items() if u["rol"] in rd]
    return {"nombre": u["nombre"], "rol": u["rol"], "empleado_id": u["empleado_id"], "secciones": SECCIONES[u["rol"]], "lee": lee, "pw_inicial": chk(DEFAULT_PW, u["password"])}

def cambiar_pw(c, u, d):
    if not chk(d.get("actual") or "", u["password"]): raise Err("La contraseña actual es incorrecta")
    if len(d.get("nueva") or "") < 6: raise Err("La nueva contraseña debe tener al menos 6 caracteres")
    c.execute("UPDATE Usuario SET password=? WHERE usuario_id=?", (hpw(d["nueva"]), u["usuario_id"])); return {"ok": 1}

class H(BaseHTTPRequestHandler):
    def out(self, code, obj, ctype="application/json", hdr=None):
        b = obj if isinstance(obj, bytes) else json.dumps(obj, ensure_ascii=False).encode()
        self.send_response(code); self.send_header("Content-Type", ctype + "; charset=utf-8"); self.send_header("Cache-Control", "no-store")
        for k, v in (hdr or {}).items(): self.send_header(k, v)
        self.send_header("Content-Length", str(len(b))); self.end_headers(); self.wfile.write(b)
    def sid(self):
        ck = SimpleCookie(self.headers.get("Cookie", "")); return ck["sid"].value if "sid" in ck else None
    def do_GET(self):
        if self.path in ("/", "/index.html"): return self.out(200, open(os.path.join(D, "index.html"), "rb").read(), "text/html")
        c = db()
        try:
            u = quien(c, self.sid())
            if not u: return self.out(401, {"error": "Sesión expirada, vuelve a ingresar"})
            if self.path == "/api/me": return self.out(200, perfil(u))
            ruta = "export" if self.path == "/export.sql" else self.path[5:]
            if not permitido(u["rol"], ruta, False): return self.out(403, {"error": "No tienes permiso para esta sección"})
            if ruta == "export":
                b = "\n".join(c.iterdump()).encode("utf-8")
                self.send_response(200); self.send_header("Content-Disposition", "attachment; filename=minimarket_altes.sql"); self.end_headers(); return self.wfile.write(b)
            data = get(c, ruta)
            if u["rol"] == "cajero" and ruta == "productos": data = [{k: v for k, v in p.items() if k != "precio_compra"} for p in data]
            self.out(200, data)
        except Err as e: self.out(404, {"error": str(e)})
        finally: c.close()
    def do_POST(self):
        d = json.loads(self.rfile.read(int(self.headers.get("Content-Length", 0))) or "{}"); ent = self.path[5:]; c = db()
        try:
            if ent == "login":
                return self.out(200, {"ok": 1}, hdr={"Set-Cookie": f"sid={login(c, d)}; HttpOnly; SameSite=Strict; Path=/"})
            if ent == "logout":
                SESSIONS.pop(self.sid(), None); return self.out(200, {"ok": 1}, hdr={"Set-Cookie": "sid=; Max-Age=0; Path=/"})
            u = quien(c, self.sid())
            if not u: return self.out(401, {"error": "Sesión expirada, vuelve a ingresar"})
            if ent == "password": r = cambiar_pw(c, u, d)
            elif not permitido(u["rol"], ent, True): return self.out(403, {"error": "No tienes permiso para esta acción"})
            else:
                d["empleado_id"] = u["empleado_id"]  # quien actúa es siempre el usuario con sesión iniciada
                if ent in ("clientes", "productos", "proveedores", "empleados"): guardar(c, ent, d); r = {"ok": 1}
                elif ent == "ventas": r = vender(c, d)
                elif ent == "compras": r = comprar(c, d)
                elif ent == "caja": r = caja(c, d)
                elif ent == "sql": r = sql_run(d)
                elif ent == "empleados/estado":
                    if int(d["id"]) == u["empleado_id"] and not d.get("estado"): raise Err("No puedes darte de baja a ti mismo")
                    c.execute("UPDATE Empleado SET estado=? WHERE empleado_id=?", (1 if d.get("estado") else 0, d["id"]))
                    c.execute("UPDATE Usuario SET estado=? WHERE empleado_id=?", (1 if d.get("estado") else 0, d["id"])); r = {"ok": 1}
                elif ent == "productos/estado":
                    c.execute("UPDATE Producto SET estado=? WHERE producto_id=?", (1 if d.get("estado") else 0, d["id"])); r = {"ok": 1}
                else: raise Err("Ruta no encontrada")
            c.commit(); self.out(200, r)
        except (Err, ValueError, KeyError, TypeError) as e:
            c.rollback(); self.out(400, {"error": str(e) if isinstance(e, Err) else "Datos inválidos, revisa el formulario"})
        finally: c.close()
    def log_message(self, *a): pass

if __name__ == "__main__":
    init()
    for port in range(8000, 8011):  # si el 8000 está ocupado (otra copia abierta), usa el siguiente
        try: srv = ThreadingHTTPServer(("127.0.0.1", port), H); break
        except OSError: continue
    url = f"http://localhost:{port}"
    print(f"Minimarket ALTES funcionando en {url}  (Ctrl+C para detener)")
    webbrowser.open(url); srv.serve_forever()
