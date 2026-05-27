from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from . import models, schemas, auth, database

models.Base.metadata.create_all(bind=database.engine)
app = FastAPI(title="SMAT API - Unidad I")

# CONFIGURACIÓN CRÍTICA PARA SEMANA 5 (CONEXIÓN MÓVIL)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.post("/token", tags=["Seguridad"])
def login():
    return {"access_token": auth.crear_token({"sub": "admin_fisi"}), "token_type": "bearer"}

@app.get("/estaciones/", response_model=list[schemas.Estacion], tags=["SMAT"])
def listar_estaciones(db: Session = Depends(database.get_db)):
    return db.query(models.EstacionDB).all()

@app.post("/estaciones/", tags=["SMAT"])
def crear_estacion(estacion: schemas.EstacionCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    try:
        datos = estacion.model_dump() if hasattr(estacion, 'model_dump') else estacion.dict()
        
        nueva = models.EstacionDB(**datos)
        db.add(nueva)
        db.commit()
        db.refresh(nueva)
        return nueva
    except Exception as e:
        db.rollback()
        print(f"ERROR REAL: {e}") # Mira esto en tu terminal negra
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/estaciones/{estacion_id}", tags=["SMAT"])
def editar_estacion(estacion_id: int, estacion: schemas.EstacionCreate, db: Session = Depends(database.get_db)):
    estacion_db = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion_id).first()
    if not estacion_db:
        raise HTTPException(status_code=404, detail="No encontrada")
    
    estacion_db.nombre = estacion.nombre
    estacion_db.ubicacion = estacion.ubicacion
    estacion_db.valor = estacion.valor  # <--- ASEGÚRATE DE QUE ESTA LÍNEA ESTÉ AQUÍ
    
    db.commit()
    return estacion_db

@app.post("/lecturas/", tags=["Telemetría"])
def registrar_lectura(lectura: schemas.LecturaCreate, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    # Reto Maestro: Validación de existencia
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    nueva_lectura = models.LecturaDB(**lectura.dict())
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura registrada con éxito"}

@app.delete("/estaciones/{estacion_id}", tags=["SMAT"])
def eliminar_estacion(estacion_id: int, db: Session = Depends(database.get_db), user=Depends(auth.validar_token)):
    # 1. Buscar si la estación existe en la DB
    estacion_db = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion_id).first()
    
    if not estacion_db:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # 2. Eliminarla físicamente
    db.delete(estacion_db)
    db.commit()
    
    return {"ok": True, "message": "Estación eliminada"}

@app.get("/lecturas/", tags=["Telemetría"])
def listar_lecturas(db: Session = Depends(database.get_db)):
    """Permite que la App Móvil consulte y muestre el historial de telemetría."""
    return db.query(models.LecturaDB).all()