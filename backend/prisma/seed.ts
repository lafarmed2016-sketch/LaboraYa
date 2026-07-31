import { PrismaClient } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // Create categories
  const categories = [
    { name: 'Plomería', icon: 'plumbing', order: 1 },
    { name: 'Albañilería', icon: 'construction', order: 2 },
    { name: 'Electricidad', icon: 'electrical_services', order: 3 },
    { name: 'Pintura', icon: 'format_paint', order: 4 },
    { name: 'Carpintería', icon: 'carpenter', order: 5 },
    { name: 'Cerrajería', icon: 'lock', order: 6 },
    { name: 'Limpieza', icon: 'cleaning_services', order: 7 },
    { name: 'Jardinería', icon: 'grass', order: 8 },
    { name: 'Construcción', icon: 'domain', order: 9 },
    { name: 'Reparación de electrodomésticos', icon: 'kitchen', order: 10 },
    { name: 'Mecánica', icon: 'build', order: 11 },
    { name: 'Refrigeración', icon: 'ac_unit', order: 12 },
    { name: 'Tecnología', icon: 'computer', order: 13 },
    { name: 'Transporte', icon: 'local_shipping', order: 14 },
    { name: 'Mudanzas', icon: 'move_to_inbox', order: 15 },
    { name: 'Cocina', icon: 'restaurant', order: 16 },
    { name: 'Atención al cliente', icon: 'support_agent', order: 17 },
    { name: 'Ventas', icon: 'storefront', order: 18 },
    { name: 'Reparto', icon: 'delivery_dining', order: 19 },
    { name: 'Seguridad', icon: 'security', order: 20 },
    { name: 'Cuidado de personas', icon: 'elderly', order: 21 },
    { name: 'Servicios domésticos', icon: 'home', order: 22 },
    { name: 'Trabajo administrativo', icon: 'description', order: 23 },
    { name: 'Otros', icon: 'more_horiz', order: 24 },
  ];

  for (const cat of categories) {
    await prisma.category.upsert({
      where: { name: cat.name },
      update: {},
      create: cat,
    });
  }
  console.log(`✅ ${categories.length} categorías creadas`);

  // Create country
  await prisma.country.upsert({
    where: { code: 'PE' },
    update: {},
    create: {
      name: 'Perú',
      code: 'PE',
      currency: 'PEN',
      symbol: 'S/',
      timezone: 'America/Lima',
      active: true,
    },
  });

  // Create admin user
  const adminPassword = await argon2.hash('Admin123!');
  await prisma.user.upsert({
    where: { email: 'admin@laboraya.com' },
    update: {},
    create: {
      email: 'admin@laboraya.com',
      firstName: 'Admin',
      lastName: 'LaboraYa',
      passwordHash: adminPassword,
      role: 'SUPER_ADMIN',
      userType: 'BOTH',
      emailVerified: true,
      city: 'Lima',
    },
  });
  console.log('✅ Usuario admin creado (admin@laboraya.com / Admin123!)');

  // Create test worker
  const workerPassword = await argon2.hash('Worker123!');
  const worker = await prisma.user.upsert({
    where: { email: 'trabajador@test.com' },
    update: {},
    create: {
      email: 'trabajador@test.com',
      firstName: 'Juan',
      lastName: 'Pérez',
      phone: '987654321',
      passwordHash: workerPassword,
      role: 'USER',
      userType: 'WORKER',
      emailVerified: true,
      city: 'Lima',
    },
  });

  await prisma.workerProfile.upsert({
    where: { userId: worker.id },
    update: {},
    create: {
      userId: worker.id,
      description: 'Plomero con 10 años de experiencia en instalaciones y reparaciones.',
      yearsExperience: 10,
      available: true,
      radiusKm: 15,
      averageRating: 4.8,
      totalReviews: 32,
      completedJobs: 48,
    },
  });
  console.log('✅ Trabajador de prueba creado (trabajador@test.com / Worker123!)');

  // Create test employer
  const employerPassword = await argon2.hash('Employer123!');
  const employer = await prisma.user.upsert({
    where: { email: 'empleador@test.com' },
    update: {},
    create: {
      email: 'empleador@test.com',
      firstName: 'María',
      lastName: 'García',
      phone: '912345678',
      passwordHash: employerPassword,
      role: 'USER',
      userType: 'EMPLOYER',
      emailVerified: true,
      city: 'Lima',
    },
  });

  await prisma.employerProfile.upsert({
    where: { userId: employer.id },
    update: {},
    create: {
      userId: employer.id,
      description: 'Gestora de propiedades en Miraflores.',
      completedHires: 15,
      averageRating: 4.5,
      totalReviews: 12,
    },
  });
  console.log('✅ Empleador de prueba creado (empleador@test.com / Employer123!)');

  // Create sample jobs
  const plomeria = await prisma.category.findUnique({ where: { name: 'Plomería' } });
  const pintura = await prisma.category.findUnique({ where: { name: 'Pintura' } });

  if (plomeria && pintura) {
    await prisma.job.createMany({
      data: [
        {
          publisherId: employer.id,
          categoryId: plomeria.id,
          title: 'Reparación de fuga de agua',
          description: 'Se requiere plomero para reparar fuga de agua debajo del lavamanos del baño principal. El acceso es fácil. Traer sus herramientas.',
          address: 'Miraflores, Lima',
          latitude: -12.1186,
          longitude: -77.0318,
          modality: 'PER_DAY',
          budgetMin: 100,
          budgetMax: 150,
          currency: 'PEN',
          status: 'PUBLISHED',
          publishedAt: new Date(),
          duration: '1 día',
          materials: 'BY_WORKER',
        },
        {
          publisherId: employer.id,
          categoryId: plomeria.id,
          title: 'Instalación de grifería',
          description: 'Necesito instalar grifería nueva en cocina y baño.',
          address: 'Miraflores, Lima',
          latitude: -12.1210,
          longitude: -77.0350,
          modality: 'PER_TASK',
          budgetMin: 120,
          budgetMax: 120,
          budgetFixed: true,
          currency: 'PEN',
          status: 'PUBLISHED',
          publishedAt: new Date(),
          duration: '4 horas',
          materials: 'BY_EMPLOYER',
        },
        {
          publisherId: employer.id,
          categoryId: pintura.id,
          title: 'Pintura de departamento',
          description: 'Pintar departamento de 80m2, paredes y techo. Color blanco.',
          address: 'Barranco, Lima',
          latitude: -12.1447,
          longitude: -77.0196,
          modality: 'PER_CONTRACT',
          budgetMin: 500,
          budgetMax: 700,
          currency: 'PEN',
          status: 'PUBLISHED',
          publishedAt: new Date(),
          duration: '3 días',
          materials: 'BY_EMPLOYER',
          workersNeeded: 2,
        },
      ],
      skipDuplicates: true,
    });
    console.log('✅ 3 trabajos de prueba creados');
  }

  // App settings
  const settings = [
    { key: 'app_name', value: 'LaboraYa', type: 'string' },
    { key: 'app_version', value: '1.0.0', type: 'string' },
    { key: 'default_currency', value: 'PEN', type: 'string' },
    { key: 'default_country', value: 'PE', type: 'string' },
    { key: 'max_photos_per_job', value: '10', type: 'number' },
    { key: 'max_file_size_mb', value: '10', type: 'number' },
    { key: 'maintenance_mode', value: 'false', type: 'boolean' },
  ];

  for (const setting of settings) {
    await prisma.appSetting.upsert({
      where: { key: setting.key },
      update: { value: setting.value },
      create: setting,
    });
  }
  console.log('✅ Configuraciones iniciales creadas');

  console.log('\n🎉 Seed completado exitosamente!');
}

main()
  .catch((e) => {
    console.error('❌ Error en seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
