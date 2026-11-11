import { useEffect } from "react";

// useExportClock — opt-in deterministic timeline for bit-for-bit reproducible
// exports. Drop this hook in your animation root and compute every animated
// value from `window.__t` (seconds) instead of relying on autoplay/wall-clock.
// The capture script (DETERMINISTIC=true) waits for `window.__ready`, then calls
// `window.__seek(t)` once per frame to position the animation exactly.
//
// Example:
//   const t = useExportClock();           // seconds, advances on its own in the
//   const x = someEasing(t);              // browser; the capture script overrides
//   return <motion.rect x={x} />;         // it via __seek when exporting.
//
// Skip this entirely for real-time capture (DETERMINISTIC=false) — autoplay is
// fine for most social clips.
export function useExportClock() {
  useEffect(() => {
    window.__t = window.__t ?? 0;
    window.__seek = (t) => {
      window.__t = t;
    };
    window.__ready = true;
  }, []);
}
