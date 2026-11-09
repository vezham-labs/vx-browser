import { createRoot } from 'react-dom/client';
import { Browser } from './Browser';
import './styles.css';

const root = document.getElementById('root');
if (root) createRoot(root).render(<Browser />);
