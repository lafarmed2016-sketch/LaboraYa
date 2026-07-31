# LaboraYa - Guía de Base de Datos y API

## Resumen
Este documento contiene todo el SQL para crear la base de datos,
todos los endpoints de la API, y cómo conectar la app Flutter.

---

## 1. BASE DE DATOS (PostgreSQL + PostGIS)

### Crear la base de datos
```sql
CREATE DATABASE laboraya;
\c laboraya
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";
```

### Enums
```sql
CREATE TYPE user_role AS ENUM ('USER', 'ADMIN', 'SUPER_ADMIN');
CREATE TYPE user_type AS ENUM ('WORKER', 'EMPLOYER', 'BOTH');
CREATE TYPE user_status AS ENUM ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'BLOCKED', 'DELETED');
CREATE TYPE job_status AS ENUM ('DRAFT', 'PUBLISHED', 'RECEIVING_APPLICATIONS', 'IN_SELECTION', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'PAUSED', 'EXPIRED', 'REPORTED', 'BLOCKED');
CREATE TYPE job_modality AS ENUM ('PER_DAY', 'PER_WEEK', 'PER_MONTH', 'PER_CONTRACT', 'PER_TASK', 'FULL_TIME', 'PART_TIME');
CREATE TYPE materials_provided AS ENUM ('BY_EMPLOYER', 'BY_WORKER', 'TO_COORDINATE');
CREATE TYPE application_status AS ENUM ('SENT', 'VIEWED', 'PRESELECTED', 'ACCEPTED', 'REJECTED', 'WITHDRAWN', 'CANCELLED');
CREATE TYPE contract_status AS ENUM ('PENDING', 'ACCEPTED', 'CONFIRMED', 'IN_PROGRESS', 'PENDING_CONFIRMATION', 'COMPLETED', 'CANCELLED', 'IN_DISPUTE');
CREATE TYPE message_type AS ENUM ('TEXT', 'IMAGE', 'LOCATION', 'FILE', 'SYSTEM');
CREATE TYPE message_status AS ENUM ('SENT', 'DELIVERED', 'READ');
CREATE TYPE report_reason AS ENUM ('FALSE_CONTENT', 'SCAM', 'INAPPROPRIATE', 'ILLEGAL', 'SPAM', 'DISCRIMINATION', 'HARASSMENT', 'IMPERSONATION', 'INCORRECT_INFO', 'OTHER');
CREATE TYPE report_status AS ENUM ('OPEN', 'IN_REVIEW', 'RESOLVED', 'DISMISSED');
CREATE TYPE notification_type AS ENUM ('NEW_APPLICATION', 'APPLICATION_ACCEPTED', 'APPLICATION_REJECTED', 'NEW_MESSAGE', 'JOB_STARTING', 'JOB_STARTED', 'FINISH_REQUEST', 'JOB_COMPLETED', 'NEW_REVIEW', 'DOCUMENT_APPROVED', 'DOCUMENT_REJECTED', 'JOB_EXPIRED', 'STATUS_CHANGE', 'ADMIN_NOTICE');
CREATE TYPE payment_method AS ENUM ('CASH', 'TRANSFER', 'YAPE', 'PLIN', 'TO_COORDINATE');
CREATE TYPE payment_status AS ENUM ('PENDING', 'CONFIRMED', 'DISPUTED');
CREATE TYPE verification_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED');
```

### Tabla: users
```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email VARCHAR(255) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE,
  password_hash TEXT NOT NULL,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  avatar TEXT,
  role user_role DEFAULT 'USER',
  user_type user_type DEFAULT 'BOTH',
  status user_status DEFAULT 'ACTIVE',
  email_verified BOOLEAN DEFAULT false,
  phone_verified BOOLEAN DEFAULT false,
  city VARCHAR(100),
  date_of_birth DATE,
  last_login_at TIMESTAMP,
  login_attempts INT DEFAULT 0,
  locked_until TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
```

### Tabla: worker_profiles
```sql
CREATE TABLE worker_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  description TEXT,
  years_experience INT,
  available BOOLEAN DEFAULT true,
  radius_km FLOAT DEFAULT 10,
  hourly_rate FLOAT,
  languages TEXT[],
  portfolio TEXT[],
  completed_jobs INT DEFAULT 0,
  cancelled_jobs INT DEFAULT 0,
  average_rating FLOAT DEFAULT 0,
  total_reviews INT DEFAULT 0,
  location GEOMETRY(POINT, 4326),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_worker_location ON worker_profiles USING GIST(location);
```

### Tabla: employer_profiles
```sql
CREATE TABLE employer_profiles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  company_name VARCHAR(200),
  company_type VARCHAR(50),
  ruc VARCHAR(20),
  description TEXT,
  logo TEXT,
  completed_hires INT DEFAULT 0,
  average_rating FLOAT DEFAULT 0,
  total_reviews INT DEFAULT 0,
  verified BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: categories
```sql
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name VARCHAR(100) UNIQUE NOT NULL,
  description TEXT,
  icon VARCHAR(50),
  image TEXT,
  active BOOLEAN DEFAULT true,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: jobs
```sql
CREATE TABLE jobs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  publisher_id UUID NOT NULL REFERENCES users(id),
  category_id UUID NOT NULL REFERENCES categories(id),
  title VARCHAR(200) NOT NULL,
  description TEXT NOT NULL,
  address VARCHAR(300),
  reference VARCHAR(200),
  latitude FLOAT,
  longitude FLOAT,
  location GEOMETRY(POINT, 4326),
  required_date DATE,
  required_time VARCHAR(20),
  end_date DATE,
  duration VARCHAR(100),
  workers_needed INT DEFAULT 1,
  experience_req VARCHAR(200),
  materials materials_provided DEFAULT 'TO_COORDINATE',
  modality job_modality NOT NULL,
  budget_min FLOAT,
  budget_max FLOAT,
  budget_fixed BOOLEAN DEFAULT false,
  currency VARCHAR(10) DEFAULT 'PEN',
  is_urgent BOOLEAN DEFAULT false,
  is_remote BOOLEAN DEFAULT false,
  status job_status DEFAULT 'DRAFT',
  applicants_count INT DEFAULT 0,
  views_count INT DEFAULT 0,
  apply_deadline TIMESTAMP,
  published_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  deleted_at TIMESTAMP
);
CREATE INDEX idx_jobs_publisher ON jobs(publisher_id);
CREATE INDEX idx_jobs_category ON jobs(category_id);
CREATE INDEX idx_jobs_status ON jobs(status);
CREATE INDEX idx_jobs_location ON jobs USING GIST(location);
CREATE INDEX idx_jobs_modality ON jobs(modality);
```

### Tabla: job_images
```sql
CREATE TABLE job_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: applications
```sql
CREATE TABLE applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL REFERENCES jobs(id),
  applicant_id UUID NOT NULL REFERENCES users(id),
  message TEXT,
  proposed_budget FLOAT,
  estimated_time VARCHAR(100),
  availability VARCHAR(200),
  status application_status DEFAULT 'SENT',
  viewed_at TIMESTAMP,
  responded_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(job_id, applicant_id)
);
CREATE INDEX idx_applications_job ON applications(job_id);
CREATE INDEX idx_applications_applicant ON applications(applicant_id);
```

### Tabla: contracts
```sql
CREATE TABLE contracts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID NOT NULL REFERENCES jobs(id),
  application_id UUID UNIQUE NOT NULL REFERENCES applications(id),
  worker_id UUID NOT NULL REFERENCES users(id),
  employer_id UUID NOT NULL REFERENCES users(id),
  status contract_status DEFAULT 'PENDING',
  agreed_budget FLOAT,
  payment_method payment_method DEFAULT 'TO_COORDINATE',
  payment_status payment_status DEFAULT 'PENDING',
  started_at TIMESTAMP,
  completed_at TIMESTAMP,
  cancelled_at TIMESTAMP,
  cancel_reason TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: conversations
```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  job_id UUID,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE conversation_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id),
  last_read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(conversation_id, user_id)
);

CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id),
  content TEXT,
  type message_type DEFAULT 'TEXT',
  status message_status DEFAULT 'SENT',
  reply_to_id UUID REFERENCES messages(id),
  deleted_for_all BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_messages_conversation ON messages(conversation_id);
```

### Tabla: reviews
```sql
CREATE TABLE reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  contract_id UUID NOT NULL REFERENCES contracts(id),
  reviewer_id UUID NOT NULL REFERENCES users(id),
  reviewed_id UUID NOT NULL REFERENCES users(id),
  rating FLOAT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  quality INT CHECK (quality >= 1 AND quality <= 5),
  punctuality INT CHECK (punctuality >= 1 AND punctuality <= 5),
  communication INT CHECK (communication >= 1 AND communication <= 5),
  professionalism INT CHECK (professionalism >= 1 AND professionalism <= 5),
  compliance INT CHECK (compliance >= 1 AND compliance <= 5),
  visible BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(contract_id, reviewer_id)
);
```

### Tabla: notifications
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  data JSONB,
  read BOOLEAN DEFAULT false,
  read_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX idx_notifications_user ON notifications(user_id);
```

### Tabla: favorites
```sql
CREATE TABLE favorites (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  job_id UUID REFERENCES jobs(id) ON DELETE CASCADE,
  target_id UUID,
  type VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, job_id, type)
);
```

### Tabla: reports
```sql
CREATE TABLE reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES users(id),
  reported_id UUID REFERENCES users(id),
  job_id UUID REFERENCES jobs(id),
  reason report_reason NOT NULL,
  description TEXT,
  status report_status DEFAULT 'OPEN',
  resolution TEXT,
  resolved_by UUID,
  resolved_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: documents (verificación)
```sql
CREATE TABLE documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  url TEXT NOT NULL,
  status verification_status DEFAULT 'PENDING',
  note TEXT,
  reviewed_by UUID,
  reviewed_at TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: refresh_tokens
```sql
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  revoked BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Tabla: devices (push notifications)
```sql
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform VARCHAR(20) NOT NULL,
  name VARCHAR(100),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, token)
);
```

### Datos iniciales (SEED)
```sql
-- Categorías
INSERT INTO categories (name, icon, sort_order) VALUES
('Plomería', 'plumbing', 1),
('Albañilería', 'construction', 2),
('Electricidad', 'electrical_services', 3),
('Pintura', 'format_paint', 4),
('Carpintería', 'carpenter', 5),
('Cerrajería', 'lock', 6),
('Limpieza', 'cleaning_services', 7),
('Jardinería', 'grass', 8),
('Mecánica', 'build', 9),
('Refrigeración', 'ac_unit', 10),
('Tecnología', 'computer', 11),
('Transporte', 'local_shipping', 12),
('Mudanzas', 'move_to_inbox', 13),
('Cocina', 'restaurant', 14),
('Seguridad', 'security', 15),
('Otros', 'more_horiz', 16);

-- Admin user (password: Admin123!)
INSERT INTO users (email, first_name, last_name, password_hash, role, user_type, email_verified, city)
VALUES ('admin@laboraya.com', 'Admin', 'LaboraYa',
'$argon2id$v=19$m=65536,t=3,p=4$hash_aqui', 'SUPER_ADMIN', 'BOTH', true, 'Lima');
```

---

## 2. API ENDPOINTS

Base URL: `https://api.laboraya.com/api/v1`

### AUTH
| Método | Endpoint | Body | Respuesta |
|--------|----------|------|-----------|
| POST | /auth/register | {firstName, lastName, email, phone, password, userType} | {accessToken, refreshToken, user} |
| POST | /auth/login | {email, password} | {accessToken, refreshToken, user} |
| POST | /auth/refresh | {refreshToken} | {accessToken, refreshToken} |
| POST | /auth/logout | - | {success} |
| POST | /auth/forgot-password | {email} | {message} |
| POST | /auth/reset-password | {token, newPassword} | {success} |
| POST | /auth/verify-email | {code} | {success} |
| POST | /auth/google | {idToken} | {accessToken, refreshToken, user} |

### USERS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /users/profile | Mi perfil completo |
| PUT | /users/profile | Actualizar perfil |
| PUT | /users/avatar | Subir foto de perfil (multipart) |
| DELETE | /users/account | Eliminar cuenta |
| GET | /users/:id | Perfil público de otro usuario |

### JOBS
| Método | Endpoint | Query params | Descripción |
|--------|----------|--------------|-------------|
| GET | /jobs | page, limit, category, modality, search, lat, lng, radius, urgent | Listar trabajos |
| GET | /jobs/nearby | lat, lng, radius | Trabajos por ubicación |
| GET | /jobs/mine | status | Mis trabajos publicados |
| GET | /jobs/:id | - | Detalle de trabajo |
| POST | /jobs | {title, description, categoryId, modality, ...} | Crear trabajo |
| PUT | /jobs/:id | {campos a actualizar} | Editar trabajo |
| DELETE | /jobs/:id | - | Eliminar trabajo |
| POST | /jobs/:id/images | file (multipart) | Subir imagen |

### APPLICATIONS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /applications | {jobId, message, proposedBudget} — Postularse |
| GET | /applications/mine | Mis postulaciones |
| GET | /applications/job/:jobId | Postulaciones de un trabajo (solo dueño) |
| PUT | /applications/:id/accept | Aceptar postulación |
| PUT | /applications/:id/reject | Rechazar postulación |
| PUT | /applications/:id/withdraw | Retirar mi postulación |

### CONTRACTS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /contracts | Mis contratos |
| GET | /contracts/:id | Detalle de contrato |
| PUT | /contracts/:id/status | {status, note} — Cambiar estado |

### CHAT
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /chats | Mis conversaciones |
| POST | /chats | {otherUserId, jobId} — Crear conversación |
| GET | /chats/:id/messages | page, limit — Mensajes |
| POST | /chats/:id/messages | {content, type} — Enviar mensaje |
| PUT | /chats/:id/read | Marcar como leído |

### WebSocket (Socket.IO) — namespace /chat
| Evento | Dirección | Data |
|--------|-----------|------|
| join | Client→Server | {conversationId} |
| message | Client→Server | {conversationId, content, type} |
| typing | Client→Server | {conversationId} |
| stopTyping | Client→Server | {conversationId} |
| newMessage | Server→Client | {message object} |
| userTyping | Server→Client | {userId} |
| messagesRead | Server→Client | {userId} |

### NOTIFICATIONS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /notifications | page, limit — Mis notificaciones |
| GET | /notifications/unread-count | Cantidad no leídas |
| PUT | /notifications/:id/read | Marcar una como leída |
| PUT | /notifications/read-all | Marcar todas como leídas |

### REVIEWS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /reviews | {contractId, rating, comment, quality...} |
| GET | /reviews/user/:userId | page — Calificaciones de un usuario |

### FAVORITES
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /favorites | Mis favoritos |
| POST | /favorites | {jobId, type} — Agregar |
| DELETE | /favorites/:id | Eliminar |

### CATEGORIES
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /categories | Todas las categorías activas |

### REPORTS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /reports | {reportedId, jobId, reason, description} |

### UPLOADS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /uploads | file (multipart) — Subir archivo |

### VERIFICATIONS
| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /verifications | Estado de mis verificaciones |
| POST | /verifications | {type, file} — Enviar documento |

---

## 3. FORMATO DE RESPUESTAS

### Éxito:
```json
{
  "success": true,
  "message": "Operación exitosa",
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  }
}
```

### Error:
```json
{
  "success": false,
  "message": "Error de validación",
  "code": "VALIDATION_ERROR",
  "errors": [
    { "field": "email", "message": "El correo ya está registrado" }
  ]
}
```

---

## 4. CÓMO CONECTAR EN FLUTTER

### Cambiar de Mock a Real:

En `lib/core/services/auth_service.dart`:
```dart
// Cambiar esto:
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.read(secureStorageProvider);
  return MockAuthService(storage: storage);
});

// Por esto:
final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.read(secureStorageProvider);
  final apiClient = ref.read(apiClientProvider);
  return RealAuthService(storage: storage, apiClient: apiClient);
});
```

### Cambiar jobs de mock a real:

En `lib/features/jobs/presentation/providers/jobs_provider.dart`:
```dart
// Cambiar _loadDemoJobs() por:
Future<void> loadJobs({bool refresh = false}) async {
  state = state.copyWith(isLoading: true);
  try {
    final response = await apiClient.get('/jobs', queryParameters: {
      'page': state.currentPage,
      'limit': 20,
      'category': state.categoryFilter,
      'modality': state.modalityFilter,
      'search': state.searchQuery,
    });
    final jobs = (response.data['data'] as List)
        .map((j) => JobEntity.fromJson(j))
        .toList();
    state = state.copyWith(jobs: jobs, isLoading: false);
  } catch (e) {
    state = state.copyWith(isLoading: false, error: e.toString());
  }
}
```

---

## 5. HEADERS DE AUTENTICACIÓN

Todas las peticiones autenticadas llevan:
```
Authorization: Bearer <accessToken>
Content-Type: application/json
```

El interceptor de Dio (ya creado en `auth_interceptor.dart`) se encarga automáticamente.

---

## 6. VARIABLES DE ENTORNO

Archivo `.env` del backend:
```
DATABASE_URL=postgresql://user:pass@host:5432/laboraya
JWT_SECRET=tu-secreto-jwt-super-seguro
JWT_EXPIRES_IN=15m
JWT_REFRESH_SECRET=tu-refresh-secret
JWT_REFRESH_EXPIRES_IN=7d
REDIS_HOST=localhost
REDIS_PORT=6379
APP_PORT=3000
```

Archivo de Flutter (pasar al compilar):
```
flutter run --dart-define=API_BASE_URL=https://api.laboraya.com/api/v1
```

---

## 7. CONSULTAS SQL ÚTILES

### Buscar trabajos por ubicación (radio 10km):
```sql
SELECT * FROM jobs
WHERE status = 'PUBLISHED'
AND ST_DWithin(
  location,
  ST_SetSRID(ST_MakePoint(-77.0318, -12.1186), 4326),
  10000  -- 10km en metros
)
ORDER BY created_at DESC
LIMIT 20;
```

### Trabajos por categoría con paginación:
```sql
SELECT j.*, c.name as category_name,
  u.first_name, u.last_name, u.avatar
FROM jobs j
JOIN categories c ON j.category_id = c.id
JOIN users u ON j.publisher_id = u.id
WHERE j.status = 'PUBLISHED'
AND j.deleted_at IS NULL
AND c.name = 'Plomería'
ORDER BY j.is_urgent DESC, j.created_at DESC
LIMIT 20 OFFSET 0;
```

### Contar postulaciones por trabajo:
```sql
SELECT job_id, COUNT(*) as total
FROM applications
WHERE status NOT IN ('WITHDRAWN', 'CANCELLED')
GROUP BY job_id;
```

### Rating promedio de un usuario:
```sql
SELECT reviewed_id,
  AVG(rating) as avg_rating,
  COUNT(*) as total_reviews
FROM reviews
WHERE visible = true
GROUP BY reviewed_id;
```
