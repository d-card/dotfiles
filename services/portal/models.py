"""SQLAlchemy models."""
import enum
import uuid
from datetime import datetime

from sqlalchemy import Column, String, Integer, DateTime, Enum, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from database import Base


def _new_id():
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=_new_id)
    email = Column(String(255), unique=True, nullable=False, index=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False, default="")
    stripe_customer_id = Column(String(255), nullable=True)
    is_active = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)

    instances = relationship("VMInstance", back_populates="user")
    game_servers = relationship("GameServerInstance", back_populates="user")


class Plan(Base):
    __tablename__ = "plans"

    id = Column(String, primary_key=True, default=_new_id)
    name = Column(String(100), nullable=False)
    product_type = Column(String(20), nullable=False)  # "vps" or "gameserver"
    cpu_cores = Column(Integer, nullable=False)
    ram_mb = Column(Integer, nullable=False)
    disk_gb = Column(Integer, nullable=False)
    price_cents = Column(Integer, nullable=False)
    stripe_price_id = Column(String(255), nullable=True)
    is_active = Column(Integer, default=1)


class InstanceStatus(str, enum.Enum):
    CREATING = "creating"
    RUNNING = "running"
    STOPPED = "stopped"
    SUSPENDED = "suspended"
    DELETING = "deleting"
    ERROR = "error"


class VMInstance(Base):
    __tablename__ = "vm_instances"

    id = Column(String, primary_key=True, default=_new_id)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    plan_id = Column(String, ForeignKey("plans.id"), nullable=False)
    incus_name = Column(String(100), unique=True, nullable=False)
    os_template = Column(String(100), nullable=False)
    ipv4 = Column(String(45), nullable=True)
    status = Column(Enum(InstanceStatus), default=InstanceStatus.CREATING)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="instances")
    plan = relationship("Plan")


class GameServerInstance(Base):
    __tablename__ = "gs_instances"

    id = Column(String, primary_key=True, default=_new_id)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    plan_id = Column(String, ForeignKey("plans.id"), nullable=False)
    pterodactyl_server_id = Column(String(50), nullable=True)
    game_type = Column(String(50), nullable=False)
    primary_port = Column(Integer, nullable=True)
    status = Column(Enum(InstanceStatus), default=InstanceStatus.CREATING)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="game_servers")
    plan = relationship("Plan")


class Payment(Base):
    __tablename__ = "payments"

    id = Column(String, primary_key=True, default=_new_id)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    stripe_invoice_id = Column(String(255), nullable=True)
    amount_cents = Column(Integer, nullable=False)
    status = Column(String(50), nullable=False, default="pending")
    created_at = Column(DateTime, default=datetime.utcnow)
