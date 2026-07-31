export default function Dashboard() {
  return (
    <div className="min-h-screen bg-gray-50">
      <nav className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
          <h1 className="text-xl font-bold text-blue-700">LaboraYa Admin</h1>
          <div className="flex items-center gap-4">
            <span className="text-sm text-gray-600">Administrador</span>
            <button className="text-sm text-red-600 hover:text-red-700">Cerrar sesión</button>
          </div>
        </div>
      </nav>

      <div className="max-w-7xl mx-auto px-4 py-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">Dashboard</h2>
        
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard title="Usuarios registrados" value="1,234" change="+12%" />
          <StatCard title="Trabajos publicados" value="567" change="+8%" />
          <StatCard title="Trabajos completados" value="342" change="+15%" />
          <StatCard title="Reportes abiertos" value="23" change="-5%" negative />
        </div>

        {/* Recent Activity */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white rounded-xl shadow-sm p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">Usuarios recientes</h3>
            <div className="space-y-3">
              {['Juan Pérez', 'María García', 'Carlos López', 'Ana Torres'].map((name) => (
                <div key={name} className="flex items-center justify-between py-2 border-b last:border-0">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
                      <span className="text-blue-700 text-sm font-medium">{name[0]}</span>
                    </div>
                    <span className="text-sm text-gray-700">{name}</span>
                  </div>
                  <span className="text-xs text-gray-400">Hace 2h</span>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm p-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">Trabajos recientes</h3>
            <div className="space-y-3">
              {[
                { title: 'Reparación de fuga', cat: 'Plomería' },
                { title: 'Pintura de local', cat: 'Pintura' },
                { title: 'Instalación eléctrica', cat: 'Electricidad' },
                { title: 'Limpieza profunda', cat: 'Limpieza' },
              ].map((job) => (
                <div key={job.title} className="flex items-center justify-between py-2 border-b last:border-0">
                  <div>
                    <p className="text-sm font-medium text-gray-700">{job.title}</p>
                    <p className="text-xs text-gray-400">{job.cat}</p>
                  </div>
                  <span className="text-xs bg-green-100 text-green-700 px-2 py-1 rounded">Activo</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatCard({ title, value, change, negative = false }: { title: string; value: string; change: string; negative?: boolean }) {
  return (
    <div className="bg-white rounded-xl shadow-sm p-6">
      <p className="text-sm text-gray-500 mb-1">{title}</p>
      <p className="text-2xl font-bold text-gray-800">{value}</p>
      <p className={`text-xs mt-1 ${negative ? 'text-red-500' : 'text-green-500'}`}>{change} vs mes anterior</p>
    </div>
  );
}
