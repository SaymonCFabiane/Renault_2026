import {
  Activity, ArrowLeft, Ban, Camera, ChevronLeft, ChevronRight, Images, Moon, Sun, Trash2, WandSparkles, CameraOff, Check, CircleAlert, CircleCheck, CircleX, Cpu, Gauge, ImageUp, Info, Link, Play,
  RefreshCw, ScanEye, Server, Square, Upload, Wifi, X,
} from 'lucide-react';

const MAP = {
  activity: Activity, camera: Camera, 'camera-off': CameraOff, check: Check, 'circle-alert': CircleAlert,
  'circle-check': CircleCheck, 'circle-x': CircleX, cpu: Cpu, gauge: Gauge, 'image-up': ImageUp, info: Info, link: Link,
  moon: Moon, sun: Sun, play: Play, 'arrow-left': ArrowLeft, ban: Ban, 'chevron-left': ChevronLeft,
  'chevron-right': ChevronRight, images: Images, trash: Trash2, wand: WandSparkles, 'refresh-cw': RefreshCw, 'scan-eye': ScanEye, server: Server, square: Square, upload: Upload, wifi: Wifi, x: X,
};

export default function Icon({ name, size = 18 }) {
  const C = MAP[name];
  return C ? <C className="i" size={size} strokeWidth={2} aria-hidden="true" /> : null;
}
