import {
  ArrowDown, ArrowLeftRight, ArrowUp, Bell, Boxes, Calendar, Car, Check, ChevronLeft, ChevronRight, ChevronsUpDown,
  CircleAlert, CircleCheck, CircleX, ClipboardList, EllipsisVertical, Factory, FlaskConical, History, Info, Inbox,
  Layers, LayoutDashboard, Lock, MapPin, Minus, Moon, Package, PackageCheck, PackageSearch, Plus, QrCode, RotateCcw,
  Route, ScanBarcode, ScanLine, Search, Send, SkipForward, SquareKanban, Sun, Table, Tag, Timer, TriangleAlert, Truck,
  Warehouse, X,
} from 'lucide-react';

const MAP = {
  'arrow-down': ArrowDown, 'arrow-left-right': ArrowLeftRight, 'arrow-up': ArrowUp, bell: Bell, boxes: Boxes,
  calendar: Calendar, car: Car, check: Check, 'chevron-left': ChevronLeft, 'chevron-right': ChevronRight,
  'chevrons-up-down': ChevronsUpDown, 'circle-alert': CircleAlert, 'circle-check': CircleCheck, 'circle-x': CircleX,
  'clipboard-list': ClipboardList, 'ellipsis-vertical': EllipsisVertical, factory: Factory, 'flask-conical': FlaskConical,
  history: History, info: Info, inbox: Inbox, layers: Layers, 'layout-dashboard': LayoutDashboard, lock: Lock,
  'map-pin': MapPin, minus: Minus, moon: Moon, package: Package, 'package-check': PackageCheck,
  'package-search': PackageSearch, plus: Plus, 'qr-code': QrCode, 'rotate-ccw': RotateCcw, route: Route,
  'scan-barcode': ScanBarcode, 'scan-line': ScanLine, search: Search, send: Send, 'skip-forward': SkipForward,
  'square-kanban': SquareKanban, sun: Sun, table: Table, tag: Tag, timer: Timer, 'triangle-alert': TriangleAlert,
  truck: Truck, warehouse: Warehouse, x: X,
};

export default function Icon({ name, size = 18 }) {
  const C = MAP[name];
  if (!C) return null;
  return <C className="i" size={size} strokeWidth={2} aria-hidden="true" />;
}
