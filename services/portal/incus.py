"""Incus wrapper — uses incus CLI for PoC, swap with REST API later."""
import subprocess
import json
import sys
import time
import uuid


class IncusClient:
    def _run(self, *args) -> str:
        result = subprocess.run(
            ["incus"] + list(args),
            capture_output=True,
            text=True,
            timeout=120,
        )
        if result.returncode != 0:
            raise RuntimeError(f"incus {' '.join(args)}: {result.stderr.strip()}")
        return result.stdout.strip()

    def create_vm(
        self,
        name: str,
        image: str = "images:ubuntu/24.04",
        cpu: int = 1,
        mem_mb: int = 512,
        disk_gb: int = 10,
    ) -> dict:
        inst_name = f"vps-{name[:20]}"
        self._run("launch", image, inst_name,
                   "--vm",
                   "-c", f"limits.cpu={cpu}",
                   "-c", f"limits.memory={mem_mb}MiB")
        # VMs take longer for DHCP — retry
        for _ in range(6):
            ip = self.get_ip(inst_name, wait=3)
            if ip:
                break
            time.sleep(2)
        print(f"CREATE_VM returning ip={ip}", file=sys.stderr, flush=True)
        return {"name": inst_name, "status": "running", "ip": ip}

    def start(self, name: str):
        return self._run("start", name)

    def stop(self, name: str):
        return self._run("stop", name)

    def get_ip(self, name: str, wait: int = 2) -> str | None:
        time.sleep(wait)
        try:
            out = self._run("list", name, "--format", "csv", "-c", "n4")
            print(f"GET_IP output: {out}", file=sys.stderr, flush=True)
            if "," in out:
                ip_field = out.strip().split(",")[1]
                ip = ip_field.split(" ")[0]
                return ip if ip else None
        except Exception as e:
            print(f"GET_IP error: {e}", file=sys.stderr, flush=True)
        return None

    def delete(self, name: str):
        self._run("delete", name, "--force")
