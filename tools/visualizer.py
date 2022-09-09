"""ASCII terminal visualizer for optical spectrum occupancy and network topology.
Generates link utilization heatmaps and constellation diagrams.
"""

from typing import List, Dict, Any

class TerminalVisualizer:
    @staticmethod
    def render_spectrum_heatmap(slots: List[bool], width: int = 64) -> str:
        """Renders 384 C-band 12.5 GHz slots as an ASCII block heatmap."""
        total = len(slots)
        lines = []
        lines.append("  [Optical C-Band Flexible Grid: 191.325 THz to 196.100 THz (384 x 12.5 GHz slots)]")
        lines.append("  " + "=" * (width + 2))
        
        chunk_size = total // 4  # 4 rows of 96 slots
        for row in range(4):
            start = row * 96
            end = start + 96
            row_slots = slots[start:end]
            row_chars = []
            # Compress 96 slots into width characters
            slots_per_char = 96 / width
            for i in range(width):
                s_idx = int(i * slots_per_char)
                e_idx = int((i + 1) * slots_per_char)
                slice_slots = row_slots[s_idx:e_idx]
                free_ratio = sum(slice_slots) / max(len(slice_slots), 1)
                if free_ratio == 1.0:
                    row_chars.append(".")  # 100% free
                elif free_ratio > 0.5:
                    row_chars.append(":")  # Moderately allocated
                elif free_ratio > 0.0:
                    row_chars.append("#")  # Heavily allocated
                else:
                    row_chars.append("@")  # 100% occupied
            
            f_start = 191.325 + (start * 0.0125)
            f_end = 191.325 + (end * 0.0125)
            lines.append(f"  |{''.join(row_chars)}| {f_start:.3f}-{f_end:.3f} THz")

        lines.append("  " + "=" * (width + 2))
        lines.append("  Legend: [.] Free  [:] Light Load  [#] Heavy Load  [@] Fully Occupied")
        return "\n".join(lines)

    @staticmethod
    def render_link_utilization_bar(link_id: str, src: str, tgt: str, used_slots: int, total_slots: int = 384) -> str:
        ratio = used_slots / max(total_slots, 1)
        bar_len = 30
        filled = int(ratio * bar_len)
        bar = "#" * filled + "-" * (bar_len - filled)
        return f"{link_id:4s} ({src} -> {tgt}): [{bar}] {ratio*100.0:5.1f}% ({used_slots:3d}/{total_slots:3d} slots)"

    @staticmethod
    def render_ascii_topology(nodes: List[str], links: List[Dict[str, Any]]) -> str:
        lines = []
        lines.append("  Optical Mesh Topology Overview:")
        lines.append(f"  ROADM Nodes: {len(nodes)} | Fiber Spans: {len(links)}")
        lines.append("  Link Interconnects:")
        for l in links[:12]:
            lines.append(f"    * {l['src']:4s} <---> {l['tgt']:4s}  [{l['length_km']:6.1f} km, SRLGs: {l.get('srlgs', [])}]")
        if len(links) > 12:
            lines.append(f"    * ... and {len(links) - 12} additional bidirectional spans")
        return "\n".join(lines)
