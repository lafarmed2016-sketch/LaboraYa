import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'LaboraYa - Panel Administrativo',
  description: 'Panel de administración de LaboraYa',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="es">
      <body className="antialiased">{children}</body>
    </html>
  );
}
