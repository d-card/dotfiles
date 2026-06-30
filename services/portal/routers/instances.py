"""Instance management — VPS (Incus) and game servers (Pterodactyl)."""
import secrets
import traceback
import sys
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from database import get_db
from models import User, Plan, VMInstance, GameServerInstance, InstanceStatus
from pterodactyl import PterodactylClient, GAME_EGGS
from incus import IncusClient
from routers.auth import get_current_user

router = APIRouter()
ptero = PterodactylClient()
incus = IncusClient()


class CreateInstanceRequest(BaseModel):
    plan_id: str
    os_template: str | None = None
    game_type: str | None = None
    ssh_key: str | None = None


class InstanceResponse(BaseModel):
    id: str
    plan_name: str
    product_type: str
    status: str
    ipv4: str | None
    primary_port: int | None
    panel_password: str | None = None
    created_at: str


# ---- VPS ----

@router.post("/vps", response_model=InstanceResponse, status_code=201)
def create_vps(
    req: CreateInstanceRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    plan = db.query(Plan).filter(Plan.id == req.plan_id, Plan.product_type == "vps").first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")
    result = incus.create_vm(
        name=f"vps-{user.id[:8]}",
        image=req.os_template or "images:ubuntu/24.04",
        cpu=plan.cpu_cores,
        mem_mb=plan.ram_mb,
        disk_gb=plan.disk_gb,
    )
    vm = VMInstance(user_id=user.id, plan_id=plan.id, incus_name=result["name"],
                    os_template=req.os_template or "images:ubuntu/24.04",
                    ipv4=result.get("ip"), status=InstanceStatus.RUNNING)
    db.add(vm); db.commit(); db.refresh(vm)
    return InstanceResponse(id=vm.id, plan_name=plan.name, product_type="vps",
                           status=vm.status.value, ipv4=vm.ipv4, created_at=vm.created_at.isoformat())


@router.get("/vps", response_model=list[InstanceResponse])
def list_vps(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return [InstanceResponse(id=i.id, plan_name=i.plan.name, product_type="vps",
            status=i.status.value, ipv4=i.ipv4, created_at=i.created_at.isoformat())
            for i in db.query(VMInstance).filter(VMInstance.user_id == user.id).all()]


# ---- Game Server ----

@router.post("/gameserver", response_model=InstanceResponse, status_code=201)
def create_gameserver(
    req: CreateInstanceRequest,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    plan = db.query(Plan).filter(Plan.id == req.plan_id, Plan.product_type == "gameserver").first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    game = GAME_EGGS.get(req.game_type or "minecraft-paper")
    if not game:
        raise HTTPException(status_code=400, detail=f"Unknown game type: {req.game_type}")

    # Allocation
    alloc = ptero.get_free_allocation(1)
    if not alloc:
        port = 25570 + secrets.randbelow(20)
        ptero._req("POST", "/nodes/1/allocations", json={"ip": "192.168.1.237", "ports": [str(port)]})
        alloc = ptero.get_free_allocation(1)
    if not alloc: raise HTTPException(status_code=500, detail="No free allocations")
    alloc_id, alloc_port = alloc["attributes"]["id"], alloc["attributes"]["port"]

    # Pterodactyl user
    username = f"user_{user.id[:8]}"
    existing = ptero.get_user_by_username(username)
    if existing:
        ptero_user_id = existing["attributes"]["id"]
    else:
        ptero_user = ptero.create_user(email=user.email, username=username,
                                       first_name=user.full_name or "Customer", last_name=user.id[:8])
        ptero_user_id = ptero_user["attributes"]["id"]

    # Set panel password
    panel_password = secrets.token_urlsafe(12)
    try:
        ptero.update_user(user_id=ptero_user_id, email=user.email, username=username,
                         first_name=user.full_name or "Customer", last_name=user.id[:8], password=panel_password)
    except Exception as e:
        traceback.print_exc(file=sys.stderr)
        panel_password = None

    # Create server
    egg = {"docker_image": "ghcr.io/pterodactyl/yolks:java_21",
           "startup": "java -Xms128M -Xmx{{SERVER_MEMORY}}M -jar {{SERVER_JARFILE}}",
           "environment": {"MINECRAFT_VERSION": "latest", "SERVER_JARFILE": "server.jar",
                          "DL_PATH": "", "BUILD_NUMBER": "latest"}}
    ptero_server = ptero.create_server(
        name=f"{game['name']} - {user.email.split('@')[0]}",
        user_id=ptero_user_id, egg_id=game["egg"], docker_image=egg["docker_image"],
        startup=egg["startup"], environment=egg["environment"],
        limits={"memory": plan.ram_mb, "disk": plan.disk_gb * 1024, "cpu": plan.cpu_cores * 100},
        allocation_id=alloc_id)

    gs = GameServerInstance(user_id=user.id, plan_id=plan.id,
                           pterodactyl_server_id=str(ptero_server["attributes"]["id"]),
                           game_type=req.game_type or "minecraft-paper",
                           primary_port=alloc_port, status=InstanceStatus.RUNNING)
    db.add(gs); db.commit(); db.refresh(gs)
    return InstanceResponse(id=gs.id, plan_name=plan.name, product_type="gameserver",
                           status=gs.status.value, ipv4="192.168.1.237",
                           primary_port=gs.primary_port, panel_password=panel_password,
                           created_at=gs.created_at.isoformat())


@router.get("/gameserver", response_model=list[InstanceResponse])
def list_gameservers(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return [InstanceResponse(id=i.id, plan_name=i.plan.name, product_type="gameserver",
            status=i.status.value, ipv4="192.168.1.237", primary_port=i.primary_port,
            created_at=i.created_at.isoformat())
            for i in db.query(GameServerInstance).filter(GameServerInstance.user_id == user.id).all()]


@router.get("", response_model=list[InstanceResponse])
def list_all(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return list_vps(user, db) + list_gameservers(user, db)
