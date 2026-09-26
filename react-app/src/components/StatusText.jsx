import { statusCls } from '../state/logic.js';
import Icon from './Icon.jsx';

// Status em texto colorido, sem badge. A cor sai do texto do status (ou de tone).
export default function StatusText({ children, tone, icon }) {
  return (
    <span className={`tp-status tp-status--${tone || statusCls(String(children))}`}>
      {icon && <Icon name={icon} />}
      {children}
    </span>
  );
}
