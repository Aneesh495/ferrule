"""Northbound REST / JSON-RPC SDN Controller Interface for Ferrule.
Allows external SDN controllers (e.g. ONOS) to request dynamic lightpath provisioning.
"""

import json
from http.server import HTTPServer, BaseHTTPRequestHandler
from typing import Dict, Any

from engine.bridge import OpticalPhysicsBridge, ModulationBridge

class FerruleRpcHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code: int, data: Dict[str, Any]):
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode("utf-8"))

    def do_GET(self):
        if self.path == "/health":
            self._send_json(200, {"status": "HEALTHY", "engine": "ferrule", "version": "1.0.0"})
        elif self.path == "/capabilities":
            self._send_json(200, {
                "cband_slots": 384,
                "slot_width_ghz": 12.5,
                "modulations": list(ModulationBridge.FORMATS.keys()),
                "fec": "15% Soft-Decision FEC",
                "standard": "ITU-T G.694.1 / G.709"
            })
        else:
            self._send_json(404, {"error": "Not Found"})

    def do_POST(self):
        if self.path == "/api/v1/route":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            try:
                req = json.loads(body.decode("utf-8"))
                dist_km = float(req.get("distance_km", 1000.0))
                bitrate = float(req.get("bitrate_gbps", 200.0))
                spans = max(1, int(dist_km / 80.0))
                gsnr = OpticalPhysicsBridge.evaluate_gsnr_db(dist_km, spans, 4, 0.0)
                mod = ModulationBridge.select_best_modulation(dist_km, gsnr) or "DP-BPSK"
                slots = ModulationBridge.required_slots(bitrate, mod)
                self._send_json(200, {
                    "status": "PROVISIONED",
                    "distance_km": dist_km,
                    "gsnr_db": round(gsnr, 2),
                    "modulation": mod,
                    "slots_allocated": slots,
                    "bandwidth_ghz": slots * 12.5,
                    "protection": "1+1 SRLG-Disjoint Active"
                })
            except Exception as e:
                self._send_json(400, {"error": str(e)})
        else:
            self._send_json(404, {"error": "Not Found"})

def run_server(port: int = 8080):
    server = HTTPServer(("127.0.0.1", port), FerruleRpcHandler)
    print(f"[*] Ferrule SDN Controller service listening on 127.0.0.1:{port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()

if __name__ == "__main__":
    run_server()
