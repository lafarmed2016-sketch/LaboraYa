# LaboraYa

**"Encuentra trabajo cerca de ti"**

Plataforma móvil que conecta personas que necesitan contratar trabajadores con personas que buscan empleos por día, semana, mes, contrato o tarea específica.

## Arquitectura

```
LaboraYa/
├── lib/                    # App Flutter (Android/iOS)
├── backend/                # API REST (NestJS + PostgreSQL)
├── admin/                  # Panel administrativo (Next.js)
├── android/                # Config nativa Android
├── ios/                    # Config nativa iOS
└── assets/                 # Recursos (imágenes, iconos, fuentes)
```

## Tecnologías

### Mobile (Flutter)
- Flutter 3.35+ / Dart 3.9+
- Riverpod (estado)
- GoRouter (navegación)
- Dio (HTTP)
- Freezed (modelos)
- Google Maps Flutter
- Firebase (messaging, crashlytics)
- Material Design 3

### Backend (NestJS)
- Node.js + NestJS + TypeScript
- PostgreSQL + PostGIS + Prisma ORM
- JWT (access + refresh tokens)
- Socket.IO (chat en tiempo real)
- Redis (caché, sesiones)
- Firebase Admin SDK (notificaciones)
- Swagger/OpenAPI (documentación)
- Docker + Docker Compose

### Admin (Next.js)
- Next.js 15 + React 19
- TypeScript
- Tailwind CSS
- TanStack Table

## Requisitos Previos

- Flutter SDK >= 3.35
- Node.js >= 20
- Docker & Docker Compose
- PostgreSQL 16+ con PostGIS
- Redis 7+
- Cuenta Firebase (para notificaciones)
- Google Maps API Key

## Instalación

### 1. Flutter App

```bash
cd LaboraYa
flutter pub get
flutter run
```

### 2. Backend

```bash
cd backend
cp .env.example .env
# Editar .env con tus credenciales

# Con Docker:
docker compose up -d

# Instalar dependencias:
npm install

# Generar Prisma Client:
npx prisma generate

# Ejecutar migraciones:
npx prisma migrate dev

# Seed inicial:
npm run prisma:seed

# Iniciar servidor:
npm run start:dev
```

API disponible en: http://localhost:3000/api/v1
Swagger docs: http://localhost:3000/docs

### 3. Panel Admin

```bash
cd admin
npm install
npm run dev
```

Panel disponible en: http://localhost:3001

## Configuración de Variables de Entorno

### Flutter
Las API keys se pasan como build arguments:
```bash
flutter run --dart-define=GOOGLE_MAPS_API_KEY=tu_key
```

### Backend
Copiar `.env.example` a `.env` y configurar:
- DATABASE_URL: conexión PostgreSQL
- JWT_SECRET: clave para tokens
- FIREBASE_*: credenciales Firebase
- STORAGE_*: credenciales S3/R2

## Estructura Flutter

```
lib/
├── app/
│   ├── app.dart              # Widget raíz
│   ├── router/               # GoRouter config
│   ├── theme/                # Material Design 3 theme
│   └── config/               # Environment configs
├── core/
│   ├── constants/            # Colores, spacing, API endpoints
│   ├── errors/               # Failures & Exceptions
│   ├── network/              # Dio client + interceptors
│   ├── storage/              # Secure storage
│   └── widgets/              # Componentes reutilizables
├── features/
│   ├── onboarding/           # Splash, onboarding, welcome
│   ├── authentication/       # Login, registro, recuperación
│   ├── home/                 # Pantalla principal
│   ├── jobs/                 # Buscar, crear, detalle trabajo
│   ├── applications/         # Postulaciones
│   ├── map/                  # Google Maps
│   ├── chat/                 # Mensajería en tiempo real
│   ├── contracts/            # Ciclo de contratación
│   ├── notifications/        # Centro de notificaciones
│   ├── profile/              # Perfil usuario
│   ├── reviews/              # Calificaciones
│   ├── favorites/            # Favoritos
│   ├── verification/         # Verificación identidad
│   └── settings/             # Configuración
└── main.dart
```

## Base de Datos

El esquema completo está en `backend/prisma/schema.prisma` e incluye:
- Users, profiles (worker/employer)
- Categories, subcategories, skills
- Jobs, applications, contracts
- Chat (conversations, messages)
- Reviews, favorites, reports
- Notifications, documents
- Geo-ubicación con PostGIS
- Auditoría

## API Endpoints

| Módulo | Ruta | Descripción |
|--------|------|-------------|
| Auth | POST /auth/register | Registro |
| Auth | POST /auth/login | Login |
| Auth | POST /auth/refresh | Renovar token |
| Users | GET /users/profile | Mi perfil |
| Jobs | GET /jobs | Listar trabajos |
| Jobs | POST /jobs | Crear trabajo |
| Jobs | GET /jobs/:id | Detalle trabajo |
| Applications | POST /applications | Postular |
| Chat | GET /chats | Conversaciones |
| Notifications | GET /notifications | Mis notificaciones |
| Reviews | POST /reviews | Calificar |

Documentación completa en Swagger: `/docs`

## Compilación para Producción

### APK Debug
```bash
flutter build apk --debug
```

### APK Release
```bash
flutter build apk --release --dart-define=GOOGLE_MAPS_API_KEY=KEY
```

### AAB (Google Play)
```bash
flutter build appbundle --release --dart-define=GOOGLE_MAPS_API_KEY=KEY
```

## Datos de la App

- **Nombre**: LaboraYa
- **ID Android**: com.laboraya.app
- **Idioma**: Español
- **País**: Perú
- **Moneda**: PEN (S/)
- **Zona horaria**: America/Lima

## Licencia

Propietario. Todos los derechos reservados.
