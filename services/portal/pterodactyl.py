"""Pterodactyl Application API client."""
import httpx
from config import settings


class PterodactylClient:
    def __init__(self):
        self.base = settings.pterodactyl_url.rstrip("/")
        self.headers = {
            "Authorization": f"Bearer {settings.pterodactyl_api_key}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

    def _req(self, method: str, path: str, timeout: int = 30, **kwargs) -> dict:
        url = f"{self.base}/api/application{path}"
        import sys
        print(f"PTERO REQ: {method} {url} auth=...{self.headers['Authorization'][-10:]}", file=sys.stderr, flush=True)
        r = httpx.request(method, url, headers=self.headers, timeout=timeout, **kwargs)
        r.raise_for_status()
        return r.json()

    # ---- Users ----
    def create_user(self, email: str, username: str, first_name: str, last_name: str) -> dict:
        return self._req("POST", "/users", json={
            "email": email,
            "username": username,
            "first_name": first_name,
            "last_name": last_name,
        })

    def update_user(self, user_id: int, email: str, username: str, first_name: str, last_name: str, password: str) -> dict:
        return self._req("PATCH", f"/users/{user_id}", json={
            "email": email,
            "username": username,
            "first_name": first_name,
            "last_name": last_name,
            "password": password,
        })
    def get_user_by_username(self, username: str) -> dict | None:
        """Find user by username. Returns None if not found."""
        users = self._req("GET", "/users")["data"]
        for u in users:
            if u["attributes"]["username"] == username:
                return u
        return None

    # ---- Servers ----
    def create_server(
        self,
        name: str,
        user_id: int,
        egg_id: int,
        docker_image: str,
        startup: str,
        environment: dict,
        limits: dict,
        allocation_id: int,
        node_id: int = 1,
    ) -> dict:
        return self._req("POST", "/servers", timeout=120, json={
            "name": name,
            "user": user_id,
            "egg": egg_id,
            "docker_image": docker_image,
            "startup": startup,
            "environment": environment,
            "limits": {
                "memory": limits["memory"],
                "swap": limits.get("swap", 0),
                "disk": limits["disk"],
                "io": limits.get("io", 500),
                "cpu": limits["cpu"],
            },
            "feature_limits": {
                "databases": limits.get("databases", 0),
                "allocations": limits.get("allocations", 1),
                "backups": limits.get("backups", 1),
            },
            "allocation": {"default": allocation_id},
            "node_id": node_id,
            "start_on_completion": False,
            "skip_scripts": False,
        })

    # ---- Allocations ----
    def list_allocations(self, node_id: int = 1) -> list[dict]:
        return self._req("GET", f"/nodes/{node_id}/allocations")["data"]

    def get_free_allocation(self, node_id: int = 1) -> dict | None:
        allocs = self.list_allocations(node_id)
        for a in allocs:
            if not a["attributes"].get("assigned"):
                return a
        return None

    # ---- Nests/Eggs ----
    def list_nests(self) -> list[dict]:
        return self._req("GET", "/nests")["data"]

    def get_eggs(self, nest_id: int) -> list[dict]:
        return self._req("GET", f"/nests/{nest_id}/eggs")["data"]

    def get_egg(self, nest_id: int, egg_id: int) -> dict:
        return self._req("GET", f"/nests/{nest_id}/eggs/{egg_id}")["attributes"]

    def get_egg_details(self, nest_id: int, egg_id: int) -> dict:
        """Get full egg details including docker_image and startup command."""
        r = httpx.get(
            f"{self.base}/api/application/nests/{nest_id}/eggs/{egg_id}?include=variables",
            headers=self.headers,
        )
        r.raise_for_status()
        return r.json()


# Pre-configured game eggs (from Pterodactyl seeder)
# Nest 1: Minecraft, Nest 2: Source Engine, Nest 3: Voice, Nest 4: Rust
GAME_EGGS = {
    "minecraft-vanilla":  {"nest": 1, "egg": 2,  "name": "Vanilla Minecraft"},
    "minecraft-paper":    {"nest": 1, "egg": 4,  "name": "Paper Minecraft"},
    "minecraft-forge":    {"nest": 1, "egg": 5,  "name": "Forge Minecraft"},
    "csgo":               {"nest": 2, "egg": 11, "name": "CS:GO"},
    "rust":               {"nest": 4, "egg": 14, "name": "Rust"},
}
