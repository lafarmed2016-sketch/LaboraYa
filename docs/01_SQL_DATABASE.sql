-- ============================================================================
-- LABORAYA - BASE DE DATOS COMPLETA PARA SQL SERVER 2019
-- ============================================================================
-- Motor: Microsoft SQL Server 15.x (2019)
-- Fecha: 2024
-- Descripción: Script completo - tablas, índices, SPs, triggers.
--              Copiar y ejecutar en SSMS (SQL Server Management Studio).
-- ============================================================================
-- INSTRUCCIONES:
--   1. Abrir SSMS, conectar a tu servidor
--   2. Click en "New Query"
--   3. Pegar TODO este script
--   4. Presionar F5 o "Execute"
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 1: CREAR BASE DE DATOS
-- ─────────────────────────────────────────────────────────────────────────────

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'LaboraYa')
BEGIN
    CREATE DATABASE LaboraYa;
END
GO

USE LaboraYa;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 2: TABLAS PRINCIPALES
-- ─────────────────────────────────────────────────────────────────────────────

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ USUARIOS                                                                  │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        Email               NVARCHAR(255) NOT NULL,
        Phone               NVARCHAR(20) NULL,
        PasswordHash        NVARCHAR(500) NOT NULL,
        FirstName           NVARCHAR(100) NOT NULL,
        LastName            NVARCHAR(100) NOT NULL,
        Avatar              NVARCHAR(500) NULL,
        Role                NVARCHAR(20) NOT NULL DEFAULT 'USER',         -- USER, ADMIN, SUPER_ADMIN
        UserType            NVARCHAR(20) NOT NULL DEFAULT 'BOTH',         -- WORKER, EMPLOYER, BOTH
        Status              NVARCHAR(20) NOT NULL DEFAULT 'ACTIVE',       -- ACTIVE, INACTIVE, SUSPENDED, BLOCKED, DELETED
        EmailVerified       BIT DEFAULT 0,
        PhoneVerified       BIT DEFAULT 0,
        City                NVARCHAR(100) NULL,
        DateOfBirth         DATE NULL,
        Bio                 NVARCHAR(500) NULL,
        LastLoginAt         DATETIME2 NULL,
        LoginAttempts       INT DEFAULT 0,
        LockedUntil         DATETIME2 NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        DeletedAt           DATETIME2 NULL,

        CONSTRAINT UQ_Users_Email UNIQUE (Email),
        CONSTRAINT UQ_Users_Phone UNIQUE (Phone),
        CONSTRAINT CK_Users_Role CHECK (Role IN ('USER', 'ADMIN', 'SUPER_ADMIN')),
        CONSTRAINT CK_Users_UserType CHECK (UserType IN ('WORKER', 'EMPLOYER', 'BOTH')),
        CONSTRAINT CK_Users_Status CHECK (Status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED', 'BLOCKED', 'DELETED'))
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ PERFILES DE TRABAJADOR                                                    │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkerProfiles')
BEGIN
    CREATE TABLE WorkerProfiles (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        Description         NVARCHAR(2000) NULL,
        YearsExperience     INT DEFAULT 0,
        Available           BIT DEFAULT 1,
        RadiusKm            FLOAT DEFAULT 10,
        HourlyRate          DECIMAL(10,2) NULL,
        Languages           NVARCHAR(500) NULL,       -- JSON array: ["Español","Quechua"]
        Portfolio           NVARCHAR(MAX) NULL,        -- JSON array de URLs
        CompletedJobs       INT DEFAULT 0,
        CancelledJobs       INT DEFAULT 0,
        AverageRating       DECIMAL(3,2) DEFAULT 0.00,
        TotalReviews        INT DEFAULT 0,
        Latitude            FLOAT NULL,
        Longitude           FLOAT NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_WorkerProfiles_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_WorkerProfiles_User UNIQUE (UserId),
        CONSTRAINT CK_WorkerProfiles_Rating CHECK (AverageRating >= 0 AND AverageRating <= 5),
        CONSTRAINT CK_WorkerProfiles_Radius CHECK (RadiusKm > 0 AND RadiusKm <= 200)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ PERFILES DE EMPLEADOR                                                     │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'EmployerProfiles')
BEGIN
    CREATE TABLE EmployerProfiles (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        CompanyName         NVARCHAR(200) NULL,
        CompanyType         NVARCHAR(50) NULL,
        RUC                 NVARCHAR(20) NULL,
        Description         NVARCHAR(2000) NULL,
        Logo                NVARCHAR(500) NULL,
        CompletedHires      INT DEFAULT 0,
        AverageRating       DECIMAL(3,2) DEFAULT 0.00,
        TotalReviews        INT DEFAULT 0,
        Verified            BIT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_EmployerProfiles_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_EmployerProfiles_User UNIQUE (UserId),
        CONSTRAINT CK_EmployerProfiles_Rating CHECK (AverageRating >= 0 AND AverageRating <= 5)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CATEGORÍAS DE TRABAJO                                                     │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE Categories (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        Name                NVARCHAR(100) NOT NULL,
        Description         NVARCHAR(500) NULL,
        Icon                NVARCHAR(50) NULL,
        Image               NVARCHAR(500) NULL,
        Active              BIT DEFAULT 1,
        SortOrder           INT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT UQ_Categories_Name UNIQUE (Name)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ SUBCATEGORÍAS                                                             │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Subcategories')
BEGIN
    CREATE TABLE Subcategories (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        CategoryId          UNIQUEIDENTIFIER NOT NULL,
        Name                NVARCHAR(100) NOT NULL,
        Active              BIT DEFAULT 1,
        SortOrder           INT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Subcategories_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(Id),
        CONSTRAINT UQ_Subcategory_Name UNIQUE (CategoryId, Name)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ TRABAJOS / PUBLICACIONES                                                  │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Jobs')
BEGIN
    CREATE TABLE Jobs (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        PublisherId         UNIQUEIDENTIFIER NOT NULL,
        CategoryId          UNIQUEIDENTIFIER NOT NULL,
        SubcategoryId       UNIQUEIDENTIFIER NULL,
        Title               NVARCHAR(200) NOT NULL,
        Description         NVARCHAR(MAX) NOT NULL,
        Address             NVARCHAR(300) NULL,
        Reference           NVARCHAR(200) NULL,
        Latitude            FLOAT NULL,
        Longitude           FLOAT NULL,
        RequiredDate        DATE NULL,
        RequiredTime        NVARCHAR(20) NULL,
        EndDate             DATE NULL,
        Duration            NVARCHAR(100) NULL,
        WorkersNeeded       INT DEFAULT 1,
        ExperienceReq       NVARCHAR(200) NULL,
        Materials           NVARCHAR(20) DEFAULT 'TO_COORDINATE',  -- BY_EMPLOYER, BY_WORKER, TO_COORDINATE
        Modality            NVARCHAR(20) NOT NULL,                  -- PER_DAY, PER_WEEK, PER_MONTH, PER_CONTRACT, PER_TASK, FULL_TIME, PART_TIME
        BudgetMin           DECIMAL(10,2) NULL,
        BudgetMax           DECIMAL(10,2) NULL,
        BudgetFixed         BIT DEFAULT 0,
        Currency            NVARCHAR(10) DEFAULT 'PEN',
        IsUrgent            BIT DEFAULT 0,
        IsRemote            BIT DEFAULT 0,
        Status              NVARCHAR(30) DEFAULT 'DRAFT',          -- DRAFT, PUBLISHED, RECEIVING_APPLICATIONS, IN_SELECTION, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED, PAUSED, EXPIRED, REPORTED, BLOCKED
        ApplicantsCount     INT DEFAULT 0,
        ViewsCount          INT DEFAULT 0,
        ApplyDeadline       DATETIME2 NULL,
        PublishedAt         DATETIME2 NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        DeletedAt           DATETIME2 NULL,

        CONSTRAINT FK_Jobs_Users FOREIGN KEY (PublisherId) REFERENCES Users(Id),
        CONSTRAINT FK_Jobs_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(Id),
        CONSTRAINT FK_Jobs_Subcategories FOREIGN KEY (SubcategoryId) REFERENCES Subcategories(Id),
        CONSTRAINT CK_Jobs_Budget CHECK (BudgetMax IS NULL OR BudgetMin IS NULL OR BudgetMax >= BudgetMin),
        CONSTRAINT CK_Jobs_Workers CHECK (WorkersNeeded >= 1),
        CONSTRAINT CK_Jobs_Materials CHECK (Materials IN ('BY_EMPLOYER', 'BY_WORKER', 'TO_COORDINATE')),
        CONSTRAINT CK_Jobs_Modality CHECK (Modality IN ('PER_DAY', 'PER_WEEK', 'PER_MONTH', 'PER_CONTRACT', 'PER_TASK', 'FULL_TIME', 'PART_TIME'))
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ IMÁGENES DE TRABAJO                                                       │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'JobImages')
BEGIN
    CREATE TABLE JobImages (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        JobId               UNIQUEIDENTIFIER NOT NULL,
        Url                 NVARCHAR(500) NOT NULL,
        SortOrder           INT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_JobImages_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(Id) ON DELETE CASCADE
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ HABILIDADES DEL TRABAJADOR                                                │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorkerSkills')
BEGIN
    CREATE TABLE WorkerSkills (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        CategoryId          UNIQUEIDENTIFIER NOT NULL,
        YearsExperience     INT DEFAULT 0,
        Certified           BIT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_WorkerSkills_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_WorkerSkills_Categories FOREIGN KEY (CategoryId) REFERENCES Categories(Id),
        CONSTRAINT UQ_WorkerSkill UNIQUE (UserId, CategoryId)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ POSTULACIONES                                                             │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Applications')
BEGIN
    CREATE TABLE Applications (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        JobId               UNIQUEIDENTIFIER NOT NULL,
        ApplicantId         UNIQUEIDENTIFIER NOT NULL,
        Message             NVARCHAR(2000) NULL,
        ProposedBudget      DECIMAL(10,2) NULL,
        EstimatedTime       NVARCHAR(100) NULL,
        Availability        NVARCHAR(200) NULL,
        Status              NVARCHAR(20) DEFAULT 'SENT',  -- SENT, VIEWED, PRESELECTED, ACCEPTED, REJECTED, WITHDRAWN, CANCELLED
        ViewedAt            DATETIME2 NULL,
        RespondedAt         DATETIME2 NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Applications_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(Id),
        CONSTRAINT FK_Applications_Users FOREIGN KEY (ApplicantId) REFERENCES Users(Id),
        CONSTRAINT UQ_Application_Per_Job UNIQUE (JobId, ApplicantId),
        CONSTRAINT CK_Applications_Status CHECK (Status IN ('SENT', 'VIEWED', 'PRESELECTED', 'ACCEPTED', 'REJECTED', 'WITHDRAWN', 'CANCELLED'))
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CONTRATOS                                                                 │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Contracts')
BEGIN
    CREATE TABLE Contracts (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        JobId               UNIQUEIDENTIFIER NOT NULL,
        ApplicationId       UNIQUEIDENTIFIER NOT NULL,
        WorkerId            UNIQUEIDENTIFIER NOT NULL,
        EmployerId          UNIQUEIDENTIFIER NOT NULL,
        Status              NVARCHAR(30) DEFAULT 'PENDING',  -- PENDING, ACCEPTED, CONFIRMED, IN_PROGRESS, PENDING_CONFIRMATION, COMPLETED, CANCELLED, IN_DISPUTE
        AgreedBudget        DECIMAL(10,2) NULL,
        PaymentMethod       NVARCHAR(20) DEFAULT 'TO_COORDINATE',  -- CASH, TRANSFER, YAPE, PLIN, TO_COORDINATE
        PaymentStatus       NVARCHAR(20) DEFAULT 'PENDING',        -- PENDING, CONFIRMED, DISPUTED
        StartedAt           DATETIME2 NULL,
        CompletedAt         DATETIME2 NULL,
        CancelledAt         DATETIME2 NULL,
        CancelReason        NVARCHAR(500) NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Contracts_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(Id),
        CONSTRAINT FK_Contracts_Applications FOREIGN KEY (ApplicationId) REFERENCES Applications(Id),
        CONSTRAINT FK_Contracts_Worker FOREIGN KEY (WorkerId) REFERENCES Users(Id),
        CONSTRAINT FK_Contracts_Employer FOREIGN KEY (EmployerId) REFERENCES Users(Id),
        CONSTRAINT UQ_Contracts_Application UNIQUE (ApplicationId)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CONVERSACIONES                                                            │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Conversations')
BEGIN
    CREATE TABLE Conversations (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        JobId               UNIQUEIDENTIFIER NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Conversations_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(Id) ON DELETE SET NULL
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ PARTICIPANTES DE CONVERSACIÓN                                             │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ConversationParticipants')
BEGIN
    CREATE TABLE ConversationParticipants (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        ConversationId      UNIQUEIDENTIFIER NOT NULL,
        UserId              UNIQUEIDENTIFIER NOT NULL,
        LastReadAt          DATETIME2 NULL,
        Muted               BIT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ConvPart_Conversations FOREIGN KEY (ConversationId) REFERENCES Conversations(Id) ON DELETE CASCADE,
        CONSTRAINT FK_ConvPart_Users FOREIGN KEY (UserId) REFERENCES Users(Id),
        CONSTRAINT UQ_Conversation_User UNIQUE (ConversationId, UserId)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ MENSAJES                                                                  │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Messages')
BEGIN
    CREATE TABLE Messages (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        ConversationId      UNIQUEIDENTIFIER NOT NULL,
        SenderId            UNIQUEIDENTIFIER NOT NULL,
        Content             NVARCHAR(MAX) NULL,
        Type                NVARCHAR(20) DEFAULT 'TEXT',      -- TEXT, IMAGE, LOCATION, FILE, SYSTEM
        Status              NVARCHAR(20) DEFAULT 'SENT',      -- SENT, DELIVERED, READ
        ReplyToId           UNIQUEIDENTIFIER NULL,
        Metadata            NVARCHAR(MAX) NULL,               -- JSON con info extra
        DeletedForAll       BIT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Messages_Conversations FOREIGN KEY (ConversationId) REFERENCES Conversations(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Messages_Users FOREIGN KEY (SenderId) REFERENCES Users(Id),
        CONSTRAINT FK_Messages_ReplyTo FOREIGN KEY (ReplyToId) REFERENCES Messages(Id),
        CONSTRAINT CK_Messages_Type CHECK (Type IN ('TEXT', 'IMAGE', 'LOCATION', 'FILE', 'SYSTEM')),
        CONSTRAINT CK_Messages_Status CHECK (Status IN ('SENT', 'DELIVERED', 'READ'))
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ RESEÑAS / CALIFICACIONES                                                  │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Reviews')
BEGIN
    CREATE TABLE Reviews (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        ContractId          UNIQUEIDENTIFIER NOT NULL,
        ReviewerId          UNIQUEIDENTIFIER NOT NULL,
        ReviewedId          UNIQUEIDENTIFIER NOT NULL,
        Rating              DECIMAL(2,1) NOT NULL,
        Comment             NVARCHAR(2000) NULL,
        Quality             TINYINT NULL,
        Punctuality         TINYINT NULL,
        Communication       TINYINT NULL,
        Professionalism     TINYINT NULL,
        Compliance          TINYINT NULL,
        Visible             BIT DEFAULT 1,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Reviews_Contracts FOREIGN KEY (ContractId) REFERENCES Contracts(Id),
        CONSTRAINT FK_Reviews_Reviewer FOREIGN KEY (ReviewerId) REFERENCES Users(Id),
        CONSTRAINT FK_Reviews_Reviewed FOREIGN KEY (ReviewedId) REFERENCES Users(Id),
        CONSTRAINT UQ_Review_Per_Contract UNIQUE (ContractId, ReviewerId),
        CONSTRAINT CK_Reviews_Rating CHECK (Rating >= 1.0 AND Rating <= 5.0),
        CONSTRAINT CK_Reviews_Quality CHECK (Quality IS NULL OR (Quality >= 1 AND Quality <= 5)),
        CONSTRAINT CK_Reviews_Punctuality CHECK (Punctuality IS NULL OR (Punctuality >= 1 AND Punctuality <= 5)),
        CONSTRAINT CK_Reviews_Communication CHECK (Communication IS NULL OR (Communication >= 1 AND Communication <= 5)),
        CONSTRAINT CK_Reviews_Professionalism CHECK (Professionalism IS NULL OR (Professionalism >= 1 AND Professionalism <= 5)),
        CONSTRAINT CK_Reviews_Compliance CHECK (Compliance IS NULL OR (Compliance >= 1 AND Compliance <= 5)),
        CONSTRAINT CK_Reviews_NotSelf CHECK (ReviewerId != ReviewedId)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ NOTIFICACIONES                                                            │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Notifications')
BEGIN
    CREATE TABLE Notifications (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        Type                NVARCHAR(30) NOT NULL,   -- NEW_APPLICATION, APPLICATION_ACCEPTED, APPLICATION_REJECTED, NEW_MESSAGE, JOB_STARTING, JOB_COMPLETED, NEW_REVIEW, etc.
        Title               NVARCHAR(200) NOT NULL,
        Body                NVARCHAR(1000) NOT NULL,
        Data                NVARCHAR(MAX) NULL,      -- JSON con IDs relacionados
        IsRead              BIT DEFAULT 0,
        ReadAt              DATETIME2 NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Notifications_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ FAVORITOS                                                                 │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Favorites')
BEGIN
    CREATE TABLE Favorites (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        JobId               UNIQUEIDENTIFIER NULL,
        TargetUserId        UNIQUEIDENTIFIER NULL,
        Type                NVARCHAR(20) NOT NULL DEFAULT 'JOB',  -- JOB, WORKER
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Favorites_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Favorites_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(Id),
        CONSTRAINT UQ_Favorite UNIQUE (UserId, JobId, Type)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ REPORTES / DENUNCIAS                                                      │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Reports')
BEGIN
    CREATE TABLE Reports (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        ReporterId          UNIQUEIDENTIFIER NOT NULL,
        ReportedUserId      UNIQUEIDENTIFIER NULL,
        JobId               UNIQUEIDENTIFIER NULL,
        Reason              NVARCHAR(30) NOT NULL,   -- FALSE_CONTENT, SCAM, INAPPROPRIATE, ILLEGAL, SPAM, DISCRIMINATION, HARASSMENT, IMPERSONATION, INCORRECT_INFO, OTHER
        Description         NVARCHAR(2000) NULL,
        Evidence            NVARCHAR(MAX) NULL,      -- JSON array de URLs de imágenes
        Status              NVARCHAR(20) DEFAULT 'OPEN',  -- OPEN, IN_REVIEW, RESOLVED, DISMISSED
        Resolution          NVARCHAR(1000) NULL,
        ResolvedBy          UNIQUEIDENTIFIER NULL,
        ResolvedAt          DATETIME2 NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Reports_Reporter FOREIGN KEY (ReporterId) REFERENCES Users(Id),
        CONSTRAINT FK_Reports_Reported FOREIGN KEY (ReportedUserId) REFERENCES Users(Id),
        CONSTRAINT FK_Reports_Jobs FOREIGN KEY (JobId) REFERENCES Jobs(Id),
        CONSTRAINT FK_Reports_ResolvedBy FOREIGN KEY (ResolvedBy) REFERENCES Users(Id)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ DOCUMENTOS DE VERIFICACIÓN                                                │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Documents')
BEGIN
    CREATE TABLE Documents (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        Type                NVARCHAR(50) NOT NULL,    -- DNI, SELFIE, ADDRESS, CERTIFICATE
        Url                 NVARCHAR(500) NOT NULL,
        Status              NVARCHAR(20) DEFAULT 'PENDING',  -- PENDING, APPROVED, REJECTED
        Note                NVARCHAR(500) NULL,
        ReviewedBy          UNIQUEIDENTIFIER NULL,
        ReviewedAt          DATETIME2 NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Documents_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT FK_Documents_Reviewer FOREIGN KEY (ReviewedBy) REFERENCES Users(Id),
        CONSTRAINT CK_Documents_Status CHECK (Status IN ('PENDING', 'APPROVED', 'REJECTED'))
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ REFRESH TOKENS (JWT)                                                      │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RefreshTokens')
BEGIN
    CREATE TABLE RefreshTokens (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        Token               NVARCHAR(500) NOT NULL,
        DeviceId            UNIQUEIDENTIFIER NULL,
        IpAddress           NVARCHAR(45) NULL,
        UserAgent           NVARCHAR(500) NULL,
        ExpiresAt           DATETIME2 NOT NULL,
        Revoked             BIT DEFAULT 0,
        RevokedAt           DATETIME2 NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_RefreshTokens_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_RefreshTokens_Token UNIQUE (Token)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ DISPOSITIVOS (PUSH NOTIFICATIONS / FCM)                                   │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Devices')
BEGIN
    CREATE TABLE Devices (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        FcmToken            NVARCHAR(500) NOT NULL,
        Platform            NVARCHAR(20) NOT NULL,    -- android, ios, web
        DeviceName          NVARCHAR(100) NULL,
        Active              BIT DEFAULT 1,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Devices_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_Device_Token UNIQUE (UserId, FcmToken),
        CONSTRAINT CK_Devices_Platform CHECK (Platform IN ('android', 'ios', 'web'))
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ LOG DE ACTIVIDAD (AUDITORÍA)                                              │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ActivityLog')
BEGIN
    CREATE TABLE ActivityLog (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NULL,
        Action              NVARCHAR(100) NOT NULL,   -- LOGIN, LOGOUT, CREATE_JOB, APPLY, ACCEPT, etc.
        Entity              NVARCHAR(50) NOT NULL,    -- USER, JOB, APPLICATION, CONTRACT, etc.
        EntityId            UNIQUEIDENTIFIER NULL,
        Details             NVARCHAR(MAX) NULL,       -- JSON con detalles
        IpAddress           NVARCHAR(45) NULL,
        UserAgent           NVARCHAR(500) NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_ActivityLog_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE SET NULL
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ CONFIGURACIÓN DE NOTIFICACIONES POR USUARIO                               │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'NotificationSettings')
BEGIN
    CREATE TABLE NotificationSettings (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        PushEnabled         BIT DEFAULT 1,
        EmailEnabled        BIT DEFAULT 1,
        NewApplications     BIT DEFAULT 1,
        ApplicationUpdates  BIT DEFAULT 1,
        NewMessages         BIT DEFAULT 1,
        JobReminders        BIT DEFAULT 1,
        Reviews             BIT DEFAULT 1,
        Promotions          BIT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),
        UpdatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_NotifSettings_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE,
        CONSTRAINT UQ_NotifSettings_User UNIQUE (UserId)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ USUARIOS BLOQUEADOS                                                       │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BlockedUsers')
BEGIN
    CREATE TABLE BlockedUsers (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        BlockedUserId       UNIQUEIDENTIFIER NOT NULL,
        Reason              NVARCHAR(200) NULL,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_Blocked_User FOREIGN KEY (UserId) REFERENCES Users(Id),
        CONSTRAINT FK_Blocked_Target FOREIGN KEY (BlockedUserId) REFERENCES Users(Id),
        CONSTRAINT UQ_BlockedUser UNIQUE (UserId, BlockedUserId),
        CONSTRAINT CK_Blocked_NotSelf CHECK (UserId != BlockedUserId)
    );
END
GO

-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ UBICACIONES GUARDADAS                                                     │
-- └──────────────────────────────────────────────────────────────────────────┘

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SavedLocations')
BEGIN
    CREATE TABLE SavedLocations (
        Id                  UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
        UserId              UNIQUEIDENTIFIER NOT NULL,
        Label               NVARCHAR(100) NOT NULL,    -- Casa, Trabajo, etc.
        Address             NVARCHAR(300) NOT NULL,
        Latitude            FLOAT NOT NULL,
        Longitude           FLOAT NOT NULL,
        IsDefault           BIT DEFAULT 0,
        CreatedAt           DATETIME2 DEFAULT GETUTCDATE(),

        CONSTRAINT FK_SavedLocations_Users FOREIGN KEY (UserId) REFERENCES Users(Id) ON DELETE CASCADE
    );
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 3: ÍNDICES PARA RENDIMIENTO
-- ─────────────────────────────────────────────────────────────────────────────

-- Users
CREATE NONCLUSTERED INDEX IX_Users_Email ON Users(Email) WHERE DeletedAt IS NULL;
CREATE NONCLUSTERED INDEX IX_Users_Phone ON Users(Phone) WHERE Phone IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Users_Status ON Users(Status) WHERE Status != 'DELETED';
CREATE NONCLUSTERED INDEX IX_Users_City ON Users(City) WHERE City IS NOT NULL;
CREATE NONCLUSTERED INDEX IX_Users_CreatedAt ON Users(CreatedAt DESC);

-- Worker Profiles
CREATE NONCLUSTERED INDEX IX_WorkerProfiles_Available ON WorkerProfiles(Available) WHERE Available = 1;
CREATE NONCLUSTERED INDEX IX_WorkerProfiles_Rating ON WorkerProfiles(AverageRating DESC);
CREATE NONCLUSTERED INDEX IX_WorkerProfiles_Location ON WorkerProfiles(Latitude, Longitude) WHERE Latitude IS NOT NULL;

-- Jobs
CREATE NONCLUSTERED INDEX IX_Jobs_Publisher ON Jobs(PublisherId) WHERE DeletedAt IS NULL;
CREATE NONCLUSTERED INDEX IX_Jobs_Category ON Jobs(CategoryId) WHERE DeletedAt IS NULL;
CREATE NONCLUSTERED INDEX IX_Jobs_Status ON Jobs(Status) WHERE DeletedAt IS NULL;
CREATE NONCLUSTERED INDEX IX_Jobs_PublishedAt ON Jobs(PublishedAt DESC) WHERE Status = 'PUBLISHED' AND DeletedAt IS NULL;
CREATE NONCLUSTERED INDEX IX_Jobs_Urgent ON Jobs(IsUrgent, PublishedAt DESC) WHERE Status = 'PUBLISHED' AND IsUrgent = 1;
CREATE NONCLUSTERED INDEX IX_Jobs_Location ON Jobs(Latitude, Longitude) WHERE Latitude IS NOT NULL AND DeletedAt IS NULL;
CREATE NONCLUSTERED INDEX IX_Jobs_Modality ON Jobs(Modality) WHERE Status = 'PUBLISHED';
CREATE NONCLUSTERED INDEX IX_Jobs_Search ON Jobs(Title, Status, CategoryId) WHERE DeletedAt IS NULL;

-- Applications
CREATE NONCLUSTERED INDEX IX_Applications_Job ON Applications(JobId, Status);
CREATE NONCLUSTERED INDEX IX_Applications_Applicant ON Applications(ApplicantId, CreatedAt DESC);
CREATE NONCLUSTERED INDEX IX_Applications_Status ON Applications(Status);

-- Contracts
CREATE NONCLUSTERED INDEX IX_Contracts_Worker ON Contracts(WorkerId, Status);
CREATE NONCLUSTERED INDEX IX_Contracts_Employer ON Contracts(EmployerId, Status);
CREATE NONCLUSTERED INDEX IX_Contracts_Job ON Contracts(JobId);

-- Messages
CREATE NONCLUSTERED INDEX IX_Messages_Conversation ON Messages(ConversationId, CreatedAt DESC);
CREATE NONCLUSTERED INDEX IX_Messages_Sender ON Messages(SenderId);

-- Conversation Participants
CREATE NONCLUSTERED INDEX IX_ConvPart_User ON ConversationParticipants(UserId);

-- Notifications
CREATE NONCLUSTERED INDEX IX_Notifications_User ON Notifications(UserId, CreatedAt DESC);
CREATE NONCLUSTERED INDEX IX_Notifications_Unread ON Notifications(UserId) WHERE IsRead = 0;

-- Reviews
CREATE NONCLUSTERED INDEX IX_Reviews_Reviewed ON Reviews(ReviewedId) WHERE Visible = 1;

-- Refresh Tokens
CREATE NONCLUSTERED INDEX IX_RefreshTokens_User ON RefreshTokens(UserId) WHERE Revoked = 0;
CREATE NONCLUSTERED INDEX IX_RefreshTokens_Expires ON RefreshTokens(ExpiresAt) WHERE Revoked = 0;

-- Activity Log
CREATE NONCLUSTERED INDEX IX_ActivityLog_User ON ActivityLog(UserId, CreatedAt DESC);
CREATE NONCLUSTERED INDEX IX_ActivityLog_Entity ON ActivityLog(Entity, EntityId);
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 4: STORED PROCEDURES - AUTENTICACIÓN
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Registrar nuevo usuario
CREATE OR ALTER PROCEDURE sp_Auth_Register
    @Email          NVARCHAR(255),
    @Phone          NVARCHAR(20) = NULL,
    @PasswordHash   NVARCHAR(500),
    @FirstName      NVARCHAR(100),
    @LastName       NVARCHAR(100),
    @UserType       NVARCHAR(20) = 'BOTH',
    @City           NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el email no exista
    IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email AND DeletedAt IS NULL)
    BEGIN
        SELECT 0 AS Success, 'El correo ya está registrado' AS Message;
        RETURN;
    END

    -- Validar que el teléfono no exista
    IF @Phone IS NOT NULL AND EXISTS (SELECT 1 FROM Users WHERE Phone = @Phone AND DeletedAt IS NULL)
    BEGIN
        SELECT 0 AS Success, 'El teléfono ya está registrado' AS Message;
        RETURN;
    END

    DECLARE @UserId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO Users (Id, Email, Phone, PasswordHash, FirstName, LastName, UserType, City)
    VALUES (@UserId, @Email, @Phone, @PasswordHash, @FirstName, @LastName, @UserType, @City);

    -- Crear perfil de trabajador si aplica
    IF @UserType IN ('WORKER', 'BOTH')
    BEGIN
        INSERT INTO WorkerProfiles (UserId) VALUES (@UserId);
    END

    -- Crear perfil de empleador si aplica
    IF @UserType IN ('EMPLOYER', 'BOTH')
    BEGIN
        INSERT INTO EmployerProfiles (UserId) VALUES (@UserId);
    END

    -- Crear configuración de notificaciones por defecto
    INSERT INTO NotificationSettings (UserId) VALUES (@UserId);

    -- Registrar actividad
    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId)
    VALUES (@UserId, 'REGISTER', 'USER', @UserId);

    SELECT 1 AS Success, 'Usuario registrado correctamente' AS Message, @UserId AS UserId;
END
GO

-- SP: Login de usuario
CREATE OR ALTER PROCEDURE sp_Auth_Login
    @Email      NVARCHAR(255),
    @IpAddress  NVARCHAR(45) = NULL,
    @UserAgent  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserId UNIQUEIDENTIFIER;
    DECLARE @Status NVARCHAR(20);
    DECLARE @LockedUntil DATETIME2;
    DECLARE @LoginAttempts INT;

    SELECT @UserId = Id, @Status = Status, @LockedUntil = LockedUntil, @LoginAttempts = LoginAttempts
    FROM Users WHERE Email = @Email AND DeletedAt IS NULL;

    -- Usuario no encontrado
    IF @UserId IS NULL
    BEGIN
        SELECT 0 AS Success, 'Credenciales inválidas' AS Message;
        RETURN;
    END

    -- Cuenta bloqueada temporalmente
    IF @LockedUntil IS NOT NULL AND @LockedUntil > GETUTCDATE()
    BEGIN
        SELECT 0 AS Success, 'Cuenta bloqueada temporalmente. Intenta más tarde.' AS Message;
        RETURN;
    END

    -- Cuenta suspendida/bloqueada permanentemente
    IF @Status IN ('SUSPENDED', 'BLOCKED', 'DELETED')
    BEGIN
        SELECT 0 AS Success, 'Tu cuenta ha sido suspendida. Contacta soporte.' AS Message;
        RETURN;
    END

    -- Retornar datos del usuario para validar password en el backend
    SELECT
        1 AS Success,
        u.Id,
        u.Email,
        u.Phone,
        u.PasswordHash,
        u.FirstName,
        u.LastName,
        u.Avatar,
        u.Role,
        u.UserType,
        u.Status,
        u.EmailVerified,
        u.PhoneVerified,
        u.City,
        u.LoginAttempts
    FROM Users u
    WHERE u.Id = @UserId;
END
GO

-- SP: Confirmar login exitoso (llamar después de validar password)
CREATE OR ALTER PROCEDURE sp_Auth_LoginSuccess
    @UserId     UNIQUEIDENTIFIER,
    @IpAddress  NVARCHAR(45) = NULL,
    @UserAgent  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Users
    SET LastLoginAt = GETUTCDATE(),
        LoginAttempts = 0,
        LockedUntil = NULL,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @UserId;

    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId, IpAddress, UserAgent)
    VALUES (@UserId, 'LOGIN', 'USER', @UserId, @IpAddress, @UserAgent);
END
GO

-- SP: Registrar intento de login fallido
CREATE OR ALTER PROCEDURE sp_Auth_LoginFailed
    @Email NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Attempts INT;
    DECLARE @UserId UNIQUEIDENTIFIER;

    SELECT @UserId = Id, @Attempts = LoginAttempts FROM Users WHERE Email = @Email AND DeletedAt IS NULL;

    IF @UserId IS NULL RETURN;

    SET @Attempts = @Attempts + 1;

    UPDATE Users
    SET LoginAttempts = @Attempts,
        LockedUntil = CASE WHEN @Attempts >= 5 THEN DATEADD(MINUTE, 15, GETUTCDATE()) ELSE NULL END,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @UserId;

    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId, Details)
    VALUES (@UserId, 'LOGIN_FAILED', 'USER', @UserId, 
            '{"attempts":' + CAST(@Attempts AS NVARCHAR) + '}');
END
GO

-- SP: Guardar refresh token
CREATE OR ALTER PROCEDURE sp_Auth_SaveRefreshToken
    @UserId     UNIQUEIDENTIFIER,
    @Token      NVARCHAR(500),
    @ExpiresAt  DATETIME2,
    @IpAddress  NVARCHAR(45) = NULL,
    @UserAgent  NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO RefreshTokens (UserId, Token, ExpiresAt, IpAddress, UserAgent)
    VALUES (@UserId, @Token, @ExpiresAt, @IpAddress, @UserAgent);
END
GO

-- SP: Validar y refrescar token
CREATE OR ALTER PROCEDURE sp_Auth_RefreshToken
    @Token NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT rt.Id, rt.UserId, rt.ExpiresAt, rt.Revoked,
           u.Status AS UserStatus, u.Email, u.Role
    FROM RefreshTokens rt
    INNER JOIN Users u ON rt.UserId = u.Id
    WHERE rt.Token = @Token;
END
GO

-- SP: Revocar token (logout)
CREATE OR ALTER PROCEDURE sp_Auth_RevokeToken
    @Token NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE RefreshTokens
    SET Revoked = 1, RevokedAt = GETUTCDATE()
    WHERE Token = @Token;
END
GO

-- SP: Revocar todos los tokens de un usuario (logout de todos los dispositivos)
CREATE OR ALTER PROCEDURE sp_Auth_RevokeAllTokens
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE RefreshTokens
    SET Revoked = 1, RevokedAt = GETUTCDATE()
    WHERE UserId = @UserId AND Revoked = 0;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 5: STORED PROCEDURES - USUARIOS Y PERFILES
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Obtener perfil completo de un usuario
CREATE OR ALTER PROCEDURE sp_Users_GetProfile
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.Id, u.Email, u.Phone, u.FirstName, u.LastName, u.Avatar,
        u.Role, u.UserType, u.Status, u.EmailVerified, u.PhoneVerified,
        u.City, u.DateOfBirth, u.Bio, u.CreatedAt,
        wp.Description AS WorkerDescription,
        wp.YearsExperience, wp.Available, wp.RadiusKm, wp.HourlyRate,
        wp.CompletedJobs, wp.CancelledJobs, wp.AverageRating AS WorkerRating,
        wp.TotalReviews AS WorkerReviews, wp.Latitude, wp.Longitude,
        ep.CompanyName, ep.CompanyType, ep.RUC,
        ep.Description AS EmployerDescription,
        ep.CompletedHires, ep.AverageRating AS EmployerRating,
        ep.TotalReviews AS EmployerReviews, ep.Verified AS EmployerVerified
    FROM Users u
    LEFT JOIN WorkerProfiles wp ON u.Id = wp.UserId
    LEFT JOIN EmployerProfiles ep ON u.Id = ep.UserId
    WHERE u.Id = @UserId AND u.DeletedAt IS NULL;
END
GO

-- SP: Actualizar perfil de usuario
CREATE OR ALTER PROCEDURE sp_Users_UpdateProfile
    @UserId     UNIQUEIDENTIFIER,
    @FirstName  NVARCHAR(100) = NULL,
    @LastName   NVARCHAR(100) = NULL,
    @Phone      NVARCHAR(20) = NULL,
    @City       NVARCHAR(100) = NULL,
    @Bio        NVARCHAR(500) = NULL,
    @Avatar     NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Users
    SET FirstName = COALESCE(@FirstName, FirstName),
        LastName = COALESCE(@LastName, LastName),
        Phone = COALESCE(@Phone, Phone),
        City = COALESCE(@City, City),
        Bio = COALESCE(@Bio, Bio),
        Avatar = COALESCE(@Avatar, Avatar),
        UpdatedAt = GETUTCDATE()
    WHERE Id = @UserId AND DeletedAt IS NULL;

    SELECT 1 AS Success, 'Perfil actualizado' AS Message;
END
GO

-- SP: Actualizar perfil de trabajador
CREATE OR ALTER PROCEDURE sp_Users_UpdateWorkerProfile
    @UserId          UNIQUEIDENTIFIER,
    @Description     NVARCHAR(2000) = NULL,
    @YearsExperience INT = NULL,
    @Available       BIT = NULL,
    @RadiusKm        FLOAT = NULL,
    @HourlyRate      DECIMAL(10,2) = NULL,
    @Latitude        FLOAT = NULL,
    @Longitude       FLOAT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM WorkerProfiles WHERE UserId = @UserId)
    BEGIN
        INSERT INTO WorkerProfiles (UserId) VALUES (@UserId);
    END

    UPDATE WorkerProfiles
    SET Description = COALESCE(@Description, Description),
        YearsExperience = COALESCE(@YearsExperience, YearsExperience),
        Available = COALESCE(@Available, Available),
        RadiusKm = COALESCE(@RadiusKm, RadiusKm),
        HourlyRate = COALESCE(@HourlyRate, HourlyRate),
        Latitude = COALESCE(@Latitude, Latitude),
        Longitude = COALESCE(@Longitude, Longitude),
        UpdatedAt = GETUTCDATE()
    WHERE UserId = @UserId;

    SELECT 1 AS Success, 'Perfil de trabajador actualizado' AS Message;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 6: STORED PROCEDURES - TRABAJOS / PUBLICACIONES
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Crear nueva publicación de trabajo
CREATE OR ALTER PROCEDURE sp_Jobs_Create
    @PublisherId    UNIQUEIDENTIFIER,
    @CategoryId     UNIQUEIDENTIFIER,
    @SubcategoryId  UNIQUEIDENTIFIER = NULL,
    @Title          NVARCHAR(200),
    @Description    NVARCHAR(MAX),
    @Address        NVARCHAR(300) = NULL,
    @Reference      NVARCHAR(200) = NULL,
    @Latitude       FLOAT = NULL,
    @Longitude      FLOAT = NULL,
    @RequiredDate   DATE = NULL,
    @RequiredTime   NVARCHAR(20) = NULL,
    @Duration       NVARCHAR(100) = NULL,
    @WorkersNeeded  INT = 1,
    @ExperienceReq  NVARCHAR(200) = NULL,
    @Materials      NVARCHAR(20) = 'TO_COORDINATE',
    @Modality       NVARCHAR(20),
    @BudgetMin      DECIMAL(10,2) = NULL,
    @BudgetMax      DECIMAL(10,2) = NULL,
    @BudgetFixed    BIT = 0,
    @IsUrgent       BIT = 0,
    @IsRemote       BIT = 0,
    @PublishNow     BIT = 1
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JobId UNIQUEIDENTIFIER = NEWID();
    DECLARE @Status NVARCHAR(30) = CASE WHEN @PublishNow = 1 THEN 'PUBLISHED' ELSE 'DRAFT' END;
    DECLARE @PublishedAt DATETIME2 = CASE WHEN @PublishNow = 1 THEN GETUTCDATE() ELSE NULL END;

    INSERT INTO Jobs (
        Id, PublisherId, CategoryId, SubcategoryId, Title, Description,
        Address, Reference, Latitude, Longitude, RequiredDate, RequiredTime,
        Duration, WorkersNeeded, ExperienceReq, Materials, Modality,
        BudgetMin, BudgetMax, BudgetFixed, IsUrgent, IsRemote,
        Status, PublishedAt
    )
    VALUES (
        @JobId, @PublisherId, @CategoryId, @SubcategoryId, @Title, @Description,
        @Address, @Reference, @Latitude, @Longitude, @RequiredDate, @RequiredTime,
        @Duration, @WorkersNeeded, @ExperienceReq, @Materials, @Modality,
        @BudgetMin, @BudgetMax, @BudgetFixed, @IsUrgent, @IsRemote,
        @Status, @PublishedAt
    );

    -- Registrar actividad
    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId)
    VALUES (@PublisherId, 'CREATE_JOB', 'JOB', @JobId);

    SELECT 1 AS Success, 'Trabajo creado correctamente' AS Message, @JobId AS JobId;
END
GO

-- SP: Obtener feed de trabajos (con paginación y filtros)
CREATE OR ALTER PROCEDURE sp_Jobs_GetFeed
    @Page           INT = 1,
    @PageSize       INT = 20,
    @CategoryId     UNIQUEIDENTIFIER = NULL,
    @Modality       NVARCHAR(20) = NULL,
    @Search         NVARCHAR(100) = NULL,
    @IsUrgent       BIT = NULL,
    @Latitude       FLOAT = NULL,
    @Longitude      FLOAT = NULL,
    @RadiusKm       FLOAT = NULL,
    @UserId         UNIQUEIDENTIFIER = NULL  -- para excluir bloqueados
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;
    DECLARE @TotalCount INT;

    -- Contar total
    SELECT @TotalCount = COUNT(*)
    FROM Jobs j
    WHERE j.Status = 'PUBLISHED'
      AND j.DeletedAt IS NULL
      AND (@CategoryId IS NULL OR j.CategoryId = @CategoryId)
      AND (@Modality IS NULL OR j.Modality = @Modality)
      AND (@IsUrgent IS NULL OR j.IsUrgent = @IsUrgent)
      AND (@Search IS NULL OR j.Title LIKE '%' + @Search + '%' OR j.Description LIKE '%' + @Search + '%')
      AND (@Latitude IS NULL OR @Longitude IS NULL OR @RadiusKm IS NULL
           OR (j.Latitude IS NOT NULL AND j.Longitude IS NOT NULL
               AND (6371 * ACOS(
                   COS(RADIANS(@Latitude)) * COS(RADIANS(j.Latitude)) *
                   COS(RADIANS(j.Longitude) - RADIANS(@Longitude)) +
                   SIN(RADIANS(@Latitude)) * SIN(RADIANS(j.Latitude))
               )) <= @RadiusKm))
      AND (@UserId IS NULL OR j.PublisherId NOT IN (
           SELECT BlockedUserId FROM BlockedUsers WHERE UserId = @UserId));

    -- Resultados paginados
    SELECT
        j.Id, j.Title, j.Description, j.Address, j.Latitude, j.Longitude,
        j.Modality, j.BudgetMin, j.BudgetMax, j.BudgetFixed, j.Currency,
        j.IsUrgent, j.IsRemote, j.Status, j.Duration, j.WorkersNeeded,
        j.Materials, j.ApplicantsCount, j.ViewsCount, j.PublishedAt, j.CreatedAt,
        c.Id AS CategoryId, c.Name AS CategoryName, c.Icon AS CategoryIcon,
        u.Id AS PublisherId, u.FirstName AS PublisherFirstName,
        u.LastName AS PublisherLastName, u.Avatar AS PublisherAvatar,
        @TotalCount AS TotalCount,
        CEILING(CAST(@TotalCount AS FLOAT) / @PageSize) AS TotalPages
    FROM Jobs j
    INNER JOIN Categories c ON j.CategoryId = c.Id
    INNER JOIN Users u ON j.PublisherId = u.Id
    WHERE j.Status = 'PUBLISHED'
      AND j.DeletedAt IS NULL
      AND (@CategoryId IS NULL OR j.CategoryId = @CategoryId)
      AND (@Modality IS NULL OR j.Modality = @Modality)
      AND (@IsUrgent IS NULL OR j.IsUrgent = @IsUrgent)
      AND (@Search IS NULL OR j.Title LIKE '%' + @Search + '%' OR j.Description LIKE '%' + @Search + '%')
      AND (@Latitude IS NULL OR @Longitude IS NULL OR @RadiusKm IS NULL
           OR (j.Latitude IS NOT NULL AND j.Longitude IS NOT NULL
               AND (6371 * ACOS(
                   COS(RADIANS(@Latitude)) * COS(RADIANS(j.Latitude)) *
                   COS(RADIANS(j.Longitude) - RADIANS(@Longitude)) +
                   SIN(RADIANS(@Latitude)) * SIN(RADIANS(j.Latitude))
               )) <= @RadiusKm))
      AND (@UserId IS NULL OR j.PublisherId NOT IN (
           SELECT BlockedUserId FROM BlockedUsers WHERE UserId = @UserId))
    ORDER BY j.IsUrgent DESC, j.PublishedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- SP: Obtener detalle de un trabajo
CREATE OR ALTER PROCEDURE sp_Jobs_GetById
    @JobId  UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER = NULL  -- para registrar vista
AS
BEGIN
    SET NOCOUNT ON;

    -- Registrar vista (solo si no es el publicador)
    IF @UserId IS NOT NULL
    BEGIN
        DECLARE @PublisherId UNIQUEIDENTIFIER;
        SELECT @PublisherId = PublisherId FROM Jobs WHERE Id = @JobId;
        IF @PublisherId != @UserId
        BEGIN
            UPDATE Jobs SET ViewsCount = ViewsCount + 1 WHERE Id = @JobId;
        END
    END

    -- Trabajo
    SELECT
        j.*, c.Name AS CategoryName, c.Icon AS CategoryIcon,
        sc.Name AS SubcategoryName,
        u.FirstName AS PublisherFirstName, u.LastName AS PublisherLastName,
        u.Avatar AS PublisherAvatar, u.City AS PublisherCity,
        ep.AverageRating AS PublisherRating, ep.TotalReviews AS PublisherReviews,
        ep.Verified AS PublisherVerified
    FROM Jobs j
    INNER JOIN Categories c ON j.CategoryId = c.Id
    LEFT JOIN Subcategories sc ON j.SubcategoryId = sc.Id
    INNER JOIN Users u ON j.PublisherId = u.Id
    LEFT JOIN EmployerProfiles ep ON u.Id = ep.UserId
    WHERE j.Id = @JobId AND j.DeletedAt IS NULL;

    -- Imágenes del trabajo
    SELECT Id, Url, SortOrder FROM JobImages WHERE JobId = @JobId ORDER BY SortOrder;
END
GO

-- SP: Obtener mis trabajos publicados
CREATE OR ALTER PROCEDURE sp_Jobs_GetMine
    @UserId     UNIQUEIDENTIFIER,
    @Status     NVARCHAR(30) = NULL,
    @Page       INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        j.Id, j.Title, j.Status, j.Modality, j.BudgetMin, j.BudgetMax, j.BudgetFixed,
        j.IsUrgent, j.ApplicantsCount, j.ViewsCount, j.PublishedAt, j.CreatedAt,
        c.Name AS CategoryName, c.Icon AS CategoryIcon
    FROM Jobs j
    INNER JOIN Categories c ON j.CategoryId = c.Id
    WHERE j.PublisherId = @UserId
      AND j.DeletedAt IS NULL
      AND (@Status IS NULL OR j.Status = @Status)
    ORDER BY j.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- SP: Actualizar trabajo
CREATE OR ALTER PROCEDURE sp_Jobs_Update
    @JobId          UNIQUEIDENTIFIER,
    @UserId         UNIQUEIDENTIFIER,
    @Title          NVARCHAR(200) = NULL,
    @Description    NVARCHAR(MAX) = NULL,
    @Address        NVARCHAR(300) = NULL,
    @BudgetMin      DECIMAL(10,2) = NULL,
    @BudgetMax      DECIMAL(10,2) = NULL,
    @IsUrgent       BIT = NULL,
    @Status         NVARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar que sea el dueño
    IF NOT EXISTS (SELECT 1 FROM Jobs WHERE Id = @JobId AND PublisherId = @UserId AND DeletedAt IS NULL)
    BEGIN
        SELECT 0 AS Success, 'No tienes permiso para editar este trabajo' AS Message;
        RETURN;
    END

    UPDATE Jobs
    SET Title = COALESCE(@Title, Title),
        Description = COALESCE(@Description, Description),
        Address = COALESCE(@Address, Address),
        BudgetMin = COALESCE(@BudgetMin, BudgetMin),
        BudgetMax = COALESCE(@BudgetMax, BudgetMax),
        IsUrgent = COALESCE(@IsUrgent, IsUrgent),
        Status = COALESCE(@Status, Status),
        PublishedAt = CASE WHEN @Status = 'PUBLISHED' AND PublishedAt IS NULL THEN GETUTCDATE() ELSE PublishedAt END,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @JobId;

    SELECT 1 AS Success, 'Trabajo actualizado' AS Message;
END
GO

-- SP: Eliminar trabajo (soft delete)
CREATE OR ALTER PROCEDURE sp_Jobs_Delete
    @JobId  UNIQUEIDENTIFIER,
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Jobs WHERE Id = @JobId AND PublisherId = @UserId AND DeletedAt IS NULL)
    BEGIN
        SELECT 0 AS Success, 'No tienes permiso' AS Message;
        RETURN;
    END

    UPDATE Jobs SET DeletedAt = GETUTCDATE(), Status = 'CANCELLED', UpdatedAt = GETUTCDATE()
    WHERE Id = @JobId;

    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId)
    VALUES (@UserId, 'DELETE_JOB', 'JOB', @JobId);

    SELECT 1 AS Success, 'Trabajo eliminado' AS Message;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 7: STORED PROCEDURES - POSTULACIONES
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Postularse a un trabajo
CREATE OR ALTER PROCEDURE sp_Applications_Create
    @JobId          UNIQUEIDENTIFIER,
    @ApplicantId    UNIQUEIDENTIFIER,
    @Message        NVARCHAR(2000) = NULL,
    @ProposedBudget DECIMAL(10,2) = NULL,
    @EstimatedTime  NVARCHAR(100) = NULL,
    @Availability   NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- No postularse a tu propio trabajo
    IF EXISTS (SELECT 1 FROM Jobs WHERE Id = @JobId AND PublisherId = @ApplicantId)
    BEGIN
        SELECT 0 AS Success, 'No puedes postularte a tu propio trabajo' AS Message;
        RETURN;
    END

    -- No postularse dos veces
    IF EXISTS (SELECT 1 FROM Applications WHERE JobId = @JobId AND ApplicantId = @ApplicantId)
    BEGIN
        SELECT 0 AS Success, 'Ya te postulaste a este trabajo' AS Message;
        RETURN;
    END

    -- Verificar que el trabajo esté publicado
    IF NOT EXISTS (SELECT 1 FROM Jobs WHERE Id = @JobId AND Status IN ('PUBLISHED', 'RECEIVING_APPLICATIONS') AND DeletedAt IS NULL)
    BEGIN
        SELECT 0 AS Success, 'Este trabajo no acepta postulaciones' AS Message;
        RETURN;
    END

    DECLARE @AppId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO Applications (Id, JobId, ApplicantId, Message, ProposedBudget, EstimatedTime, Availability)
    VALUES (@AppId, @JobId, @ApplicantId, @Message, @ProposedBudget, @EstimatedTime, @Availability);

    -- Notificar al publicador
    DECLARE @JobTitle NVARCHAR(200);
    DECLARE @PublisherId UNIQUEIDENTIFIER;
    DECLARE @ApplicantName NVARCHAR(200);

    SELECT @JobTitle = Title, @PublisherId = PublisherId FROM Jobs WHERE Id = @JobId;
    SELECT @ApplicantName = FirstName + ' ' + LastName FROM Users WHERE Id = @ApplicantId;

    INSERT INTO Notifications (UserId, Type, Title, Body, Data)
    VALUES (@PublisherId, 'NEW_APPLICATION', 'Nueva postulación',
            @ApplicantName + ' se postuló a "' + @JobTitle + '"',
            '{"jobId":"' + CAST(@JobId AS NVARCHAR(36)) + '","applicationId":"' + CAST(@AppId AS NVARCHAR(36)) + '"}');

    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId)
    VALUES (@ApplicantId, 'APPLY', 'APPLICATION', @AppId);

    SELECT 1 AS Success, 'Postulación enviada' AS Message, @AppId AS ApplicationId;
END
GO

-- SP: Obtener postulaciones de un trabajo (para el empleador)
CREATE OR ALTER PROCEDURE sp_Applications_GetByJob
    @JobId      UNIQUEIDENTIFIER,
    @UserId     UNIQUEIDENTIFIER  -- verificar que sea el dueño
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM Jobs WHERE Id = @JobId AND PublisherId = @UserId)
    BEGIN
        SELECT 0 AS Success, 'No tienes permiso' AS Message;
        RETURN;
    END

    SELECT
        a.Id, a.Message, a.ProposedBudget, a.EstimatedTime, a.Availability,
        a.Status, a.CreatedAt,
        u.Id AS ApplicantId, u.FirstName, u.LastName, u.Avatar, u.City,
        wp.AverageRating, wp.TotalReviews, wp.CompletedJobs, wp.YearsExperience
    FROM Applications a
    INNER JOIN Users u ON a.ApplicantId = u.Id
    LEFT JOIN WorkerProfiles wp ON u.Id = wp.UserId
    WHERE a.JobId = @JobId
    ORDER BY a.CreatedAt DESC;
END
GO

-- SP: Aceptar postulación
CREATE OR ALTER PROCEDURE sp_Applications_Accept
    @ApplicationId  UNIQUEIDENTIFIER,
    @UserId         UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JobId UNIQUEIDENTIFIER;
    DECLARE @ApplicantId UNIQUEIDENTIFIER;
    DECLARE @PublisherId UNIQUEIDENTIFIER;
    DECLARE @JobTitle NVARCHAR(200);
    DECLARE @Budget DECIMAL(10,2);

    SELECT @JobId = a.JobId, @ApplicantId = a.ApplicantId, @Budget = a.ProposedBudget
    FROM Applications a WHERE a.Id = @ApplicationId;

    SELECT @PublisherId = PublisherId, @JobTitle = Title FROM Jobs WHERE Id = @JobId;

    IF @PublisherId != @UserId
    BEGIN
        SELECT 0 AS Success, 'No tienes permiso' AS Message;
        RETURN;
    END

    -- Actualizar postulación
    UPDATE Applications SET Status = 'ACCEPTED', RespondedAt = GETUTCDATE(), UpdatedAt = GETUTCDATE()
    WHERE Id = @ApplicationId;

    -- Crear contrato
    DECLARE @ContractId UNIQUEIDENTIFIER = NEWID();
    INSERT INTO Contracts (Id, JobId, ApplicationId, WorkerId, EmployerId, AgreedBudget)
    VALUES (@ContractId, @JobId, @ApplicationId, @ApplicantId, @UserId, @Budget);

    -- Cambiar estado del trabajo
    UPDATE Jobs SET Status = 'ASSIGNED', UpdatedAt = GETUTCDATE() WHERE Id = @JobId;

    -- Notificar al trabajador
    INSERT INTO Notifications (UserId, Type, Title, Body, Data)
    VALUES (@ApplicantId, 'APPLICATION_ACCEPTED', '¡Postulación aceptada!',
            'Tu postulación para "' + @JobTitle + '" fue aceptada',
            '{"jobId":"' + CAST(@JobId AS NVARCHAR(36)) + '","contractId":"' + CAST(@ContractId AS NVARCHAR(36)) + '"}');

    SELECT 1 AS Success, 'Postulación aceptada' AS Message, @ContractId AS ContractId;
END
GO

-- SP: Rechazar postulación
CREATE OR ALTER PROCEDURE sp_Applications_Reject
    @ApplicationId  UNIQUEIDENTIFIER,
    @UserId         UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @JobId UNIQUEIDENTIFIER;
    DECLARE @ApplicantId UNIQUEIDENTIFIER;
    DECLARE @JobTitle NVARCHAR(200);

    SELECT @JobId = JobId, @ApplicantId = ApplicantId FROM Applications WHERE Id = @ApplicationId;
    SELECT @JobTitle = Title FROM Jobs WHERE Id = @JobId AND PublisherId = @UserId;

    IF @JobTitle IS NULL
    BEGIN
        SELECT 0 AS Success, 'No tienes permiso' AS Message;
        RETURN;
    END

    UPDATE Applications SET Status = 'REJECTED', RespondedAt = GETUTCDATE(), UpdatedAt = GETUTCDATE()
    WHERE Id = @ApplicationId;

    INSERT INTO Notifications (UserId, Type, Title, Body, Data)
    VALUES (@ApplicantId, 'APPLICATION_REJECTED', 'Postulación no seleccionada',
            'Tu postulación para "' + @JobTitle + '" no fue seleccionada',
            '{"jobId":"' + CAST(@JobId AS NVARCHAR(36)) + '"}');

    SELECT 1 AS Success, 'Postulación rechazada' AS Message;
END
GO

-- SP: Obtener mis postulaciones
CREATE OR ALTER PROCEDURE sp_Applications_GetMine
    @UserId     UNIQUEIDENTIFIER,
    @Page       INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        a.Id, a.Status, a.ProposedBudget, a.CreatedAt, a.RespondedAt,
        j.Id AS JobId, j.Title, j.Status AS JobStatus, j.Modality,
        j.BudgetMin, j.BudgetMax, j.IsUrgent,
        c.Name AS CategoryName,
        u.FirstName AS EmployerFirstName, u.LastName AS EmployerLastName, u.Avatar AS EmployerAvatar
    FROM Applications a
    INNER JOIN Jobs j ON a.JobId = j.Id
    INNER JOIN Categories c ON j.CategoryId = c.Id
    INNER JOIN Users u ON j.PublisherId = u.Id
    WHERE a.ApplicantId = @UserId
    ORDER BY a.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 8: STORED PROCEDURES - CONTRATOS
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Cambiar estado del contrato
CREATE OR ALTER PROCEDURE sp_Contracts_UpdateStatus
    @ContractId UNIQUEIDENTIFIER,
    @UserId     UNIQUEIDENTIFIER,
    @NewStatus  NVARCHAR(30),
    @Note       NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @WorkerId UNIQUEIDENTIFIER;
    DECLARE @EmployerId UNIQUEIDENTIFIER;
    DECLARE @CurrentStatus NVARCHAR(30);
    DECLARE @JobId UNIQUEIDENTIFIER;

    SELECT @WorkerId = WorkerId, @EmployerId = EmployerId, @CurrentStatus = Status, @JobId = JobId
    FROM Contracts WHERE Id = @ContractId;

    -- Verificar que sea parte del contrato
    IF @UserId NOT IN (@WorkerId, @EmployerId)
    BEGIN
        SELECT 0 AS Success, 'No tienes permiso' AS Message;
        RETURN;
    END

    -- Actualizar contrato
    UPDATE Contracts
    SET Status = @NewStatus,
        StartedAt = CASE WHEN @NewStatus = 'IN_PROGRESS' THEN GETUTCDATE() ELSE StartedAt END,
        CompletedAt = CASE WHEN @NewStatus = 'COMPLETED' THEN GETUTCDATE() ELSE CompletedAt END,
        CancelledAt = CASE WHEN @NewStatus = 'CANCELLED' THEN GETUTCDATE() ELSE CancelledAt END,
        CancelReason = CASE WHEN @NewStatus = 'CANCELLED' THEN @Note ELSE CancelReason END,
        UpdatedAt = GETUTCDATE()
    WHERE Id = @ContractId;

    -- Actualizar estado del job
    IF @NewStatus = 'IN_PROGRESS'
        UPDATE Jobs SET Status = 'IN_PROGRESS', UpdatedAt = GETUTCDATE() WHERE Id = @JobId;
    ELSE IF @NewStatus = 'COMPLETED'
    BEGIN
        UPDATE Jobs SET Status = 'COMPLETED', UpdatedAt = GETUTCDATE() WHERE Id = @JobId;
        -- Incrementar jobs completados del trabajador
        UPDATE WorkerProfiles SET CompletedJobs = CompletedJobs + 1, UpdatedAt = GETUTCDATE()
        WHERE UserId = @WorkerId;
        -- Incrementar hires del empleador
        UPDATE EmployerProfiles SET CompletedHires = CompletedHires + 1, UpdatedAt = GETUTCDATE()
        WHERE UserId = @EmployerId;
    END

    -- Notificar a la otra parte
    DECLARE @OtherUserId UNIQUEIDENTIFIER = CASE WHEN @UserId = @WorkerId THEN @EmployerId ELSE @WorkerId END;
    DECLARE @NotifTitle NVARCHAR(200) = 'Actualización de contrato';
    DECLARE @NotifBody NVARCHAR(500) = 'El contrato cambió a estado: ' + @NewStatus;

    INSERT INTO Notifications (UserId, Type, Title, Body, Data)
    VALUES (@OtherUserId, 'STATUS_CHANGE', @NotifTitle, @NotifBody,
            '{"contractId":"' + CAST(@ContractId AS NVARCHAR(36)) + '"}');

    SELECT 1 AS Success, 'Estado actualizado a ' + @NewStatus AS Message;
END
GO

-- SP: Obtener mis contratos
CREATE OR ALTER PROCEDURE sp_Contracts_GetMine
    @UserId     UNIQUEIDENTIFIER,
    @Status     NVARCHAR(30) = NULL,
    @Page       INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        ct.Id, ct.Status, ct.AgreedBudget, ct.PaymentMethod, ct.PaymentStatus,
        ct.StartedAt, ct.CompletedAt, ct.CreatedAt,
        j.Id AS JobId, j.Title AS JobTitle, j.Modality,
        c.Name AS CategoryName,
        -- Info del otro participante
        CASE WHEN ct.WorkerId = @UserId THEN ue.FirstName ELSE uw.FirstName END AS OtherFirstName,
        CASE WHEN ct.WorkerId = @UserId THEN ue.LastName ELSE uw.LastName END AS OtherLastName,
        CASE WHEN ct.WorkerId = @UserId THEN ue.Avatar ELSE uw.Avatar END AS OtherAvatar,
        CASE WHEN ct.WorkerId = @UserId THEN 'EMPLOYER' ELSE 'WORKER' END AS MyRole
    FROM Contracts ct
    INNER JOIN Jobs j ON ct.JobId = j.Id
    INNER JOIN Categories c ON j.CategoryId = c.Id
    INNER JOIN Users uw ON ct.WorkerId = uw.Id
    INNER JOIN Users ue ON ct.EmployerId = ue.Id
    WHERE (ct.WorkerId = @UserId OR ct.EmployerId = @UserId)
      AND (@Status IS NULL OR ct.Status = @Status)
    ORDER BY ct.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 9: STORED PROCEDURES - CHAT / MENSAJES
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Crear o obtener conversación entre dos usuarios
CREATE OR ALTER PROCEDURE sp_Chat_GetOrCreateConversation
    @UserId1    UNIQUEIDENTIFIER,
    @UserId2    UNIQUEIDENTIFIER,
    @JobId      UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ConversationId UNIQUEIDENTIFIER;

    -- Buscar conversación existente entre estos dos usuarios
    SELECT TOP 1 @ConversationId = cp1.ConversationId
    FROM ConversationParticipants cp1
    INNER JOIN ConversationParticipants cp2 ON cp1.ConversationId = cp2.ConversationId
    WHERE cp1.UserId = @UserId1 AND cp2.UserId = @UserId2;

    -- Si no existe, crear una nueva
    IF @ConversationId IS NULL
    BEGIN
        SET @ConversationId = NEWID();

        INSERT INTO Conversations (Id, JobId) VALUES (@ConversationId, @JobId);
        INSERT INTO ConversationParticipants (ConversationId, UserId) VALUES (@ConversationId, @UserId1);
        INSERT INTO ConversationParticipants (ConversationId, UserId) VALUES (@ConversationId, @UserId2);
    END

    SELECT @ConversationId AS ConversationId;
END
GO

-- SP: Enviar mensaje
CREATE OR ALTER PROCEDURE sp_Chat_SendMessage
    @ConversationId UNIQUEIDENTIFIER,
    @SenderId       UNIQUEIDENTIFIER,
    @Content        NVARCHAR(MAX),
    @Type           NVARCHAR(20) = 'TEXT',
    @Metadata       NVARCHAR(MAX) = NULL,
    @ReplyToId      UNIQUEIDENTIFIER = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar que el usuario sea participante
    IF NOT EXISTS (SELECT 1 FROM ConversationParticipants WHERE ConversationId = @ConversationId AND UserId = @SenderId)
    BEGIN
        SELECT 0 AS Success, 'No eres parte de esta conversación' AS Message;
        RETURN;
    END

    DECLARE @MessageId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO Messages (Id, ConversationId, SenderId, Content, Type, Metadata, ReplyToId)
    VALUES (@MessageId, @ConversationId, @SenderId, @Content, @Type, @Metadata, @ReplyToId);

    -- Actualizar timestamp de la conversación
    UPDATE Conversations SET UpdatedAt = GETUTCDATE() WHERE Id = @ConversationId;

    -- Notificar al otro participante
    DECLARE @OtherUserId UNIQUEIDENTIFIER;
    DECLARE @SenderName NVARCHAR(200);

    SELECT TOP 1 @OtherUserId = UserId FROM ConversationParticipants
    WHERE ConversationId = @ConversationId AND UserId != @SenderId;

    SELECT @SenderName = FirstName + ' ' + LastName FROM Users WHERE Id = @SenderId;

    INSERT INTO Notifications (UserId, Type, Title, Body, Data)
    VALUES (@OtherUserId, 'NEW_MESSAGE', 'Nuevo mensaje',
            @SenderName + ' te envió un mensaje',
            '{"conversationId":"' + CAST(@ConversationId AS NVARCHAR(36)) + '"}');

    SELECT 1 AS Success, @MessageId AS MessageId;
END
GO

-- SP: Obtener mis conversaciones
CREATE OR ALTER PROCEDURE sp_Chat_GetConversations
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        c.Id AS ConversationId,
        c.UpdatedAt,
        u.Id AS ParticipantId,
        u.FirstName AS ParticipantFirstName,
        u.LastName AS ParticipantLastName,
        u.Avatar AS ParticipantAvatar,
        -- Último mensaje
        lastMsg.Content AS LastMessage,
        lastMsg.Type AS LastMessageType,
        lastMsg.CreatedAt AS LastMessageAt,
        lastMsg.SenderId AS LastMessageSenderId,
        -- No leídos
        (SELECT COUNT(*) FROM Messages m
         WHERE m.ConversationId = c.Id
         AND m.SenderId != @UserId
         AND m.CreatedAt > COALESCE(cp.LastReadAt, '1900-01-01')) AS UnreadCount
    FROM ConversationParticipants cp
    INNER JOIN Conversations c ON cp.ConversationId = c.Id
    INNER JOIN ConversationParticipants cp2 ON c.Id = cp2.ConversationId AND cp2.UserId != @UserId
    INNER JOIN Users u ON cp2.UserId = u.Id
    OUTER APPLY (
        SELECT TOP 1 Content, Type, CreatedAt, SenderId
        FROM Messages WHERE ConversationId = c.Id ORDER BY CreatedAt DESC
    ) lastMsg
    WHERE cp.UserId = @UserId
    ORDER BY COALESCE(lastMsg.CreatedAt, c.CreatedAt) DESC;
END
GO

-- SP: Obtener mensajes de una conversación
CREATE OR ALTER PROCEDURE sp_Chat_GetMessages
    @ConversationId UNIQUEIDENTIFIER,
    @UserId         UNIQUEIDENTIFIER,
    @Page           INT = 1,
    @PageSize       INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    -- Marcar como leídos
    UPDATE ConversationParticipants SET LastReadAt = GETUTCDATE()
    WHERE ConversationId = @ConversationId AND UserId = @UserId;

    -- Obtener mensajes
    SELECT
        m.Id, m.Content, m.Type, m.Status, m.Metadata,
        m.SenderId, m.ReplyToId, m.DeletedForAll, m.CreatedAt,
        u.FirstName AS SenderFirstName, u.LastName AS SenderLastName, u.Avatar AS SenderAvatar
    FROM Messages m
    INNER JOIN Users u ON m.SenderId = u.Id
    WHERE m.ConversationId = @ConversationId AND m.DeletedForAll = 0
    ORDER BY m.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 10: STORED PROCEDURES - NOTIFICACIONES
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Obtener notificaciones de un usuario
CREATE OR ALTER PROCEDURE sp_Notifications_Get
    @UserId     UNIQUEIDENTIFIER,
    @Page       INT = 1,
    @PageSize   INT = 30
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT Id, Type, Title, Body, Data, IsRead, ReadAt, CreatedAt
    FROM Notifications
    WHERE UserId = @UserId
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- SP: Contar no leídas
CREATE OR ALTER PROCEDURE sp_Notifications_UnreadCount
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT COUNT(*) AS UnreadCount FROM Notifications WHERE UserId = @UserId AND IsRead = 0;
END
GO

-- SP: Marcar una como leída
CREATE OR ALTER PROCEDURE sp_Notifications_MarkRead
    @NotificationId UNIQUEIDENTIFIER,
    @UserId         UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Notifications SET IsRead = 1, ReadAt = GETUTCDATE()
    WHERE Id = @NotificationId AND UserId = @UserId;
END
GO

-- SP: Marcar todas como leídas
CREATE OR ALTER PROCEDURE sp_Notifications_MarkAllRead
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Notifications SET IsRead = 1, ReadAt = GETUTCDATE()
    WHERE UserId = @UserId AND IsRead = 0;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 11: STORED PROCEDURES - RESEÑAS
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Crear reseña
CREATE OR ALTER PROCEDURE sp_Reviews_Create
    @ContractId     UNIQUEIDENTIFIER,
    @ReviewerId     UNIQUEIDENTIFIER,
    @Rating         DECIMAL(2,1),
    @Comment        NVARCHAR(2000) = NULL,
    @Quality        TINYINT = NULL,
    @Punctuality    TINYINT = NULL,
    @Communication  TINYINT = NULL,
    @Professionalism TINYINT = NULL,
    @Compliance     TINYINT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Verificar que el contrato esté completado
    DECLARE @ContractStatus NVARCHAR(30);
    DECLARE @WorkerId UNIQUEIDENTIFIER;
    DECLARE @EmployerId UNIQUEIDENTIFIER;

    SELECT @ContractStatus = Status, @WorkerId = WorkerId, @EmployerId = EmployerId
    FROM Contracts WHERE Id = @ContractId;

    IF @ContractStatus != 'COMPLETED'
    BEGIN
        SELECT 0 AS Success, 'Solo puedes calificar contratos completados' AS Message;
        RETURN;
    END

    -- Verificar que sea parte del contrato
    IF @ReviewerId NOT IN (@WorkerId, @EmployerId)
    BEGIN
        SELECT 0 AS Success, 'No eres parte de este contrato' AS Message;
        RETURN;
    END

    -- Determinar quién es el calificado
    DECLARE @ReviewedId UNIQUEIDENTIFIER = CASE WHEN @ReviewerId = @WorkerId THEN @EmployerId ELSE @WorkerId END;

    -- No duplicar
    IF EXISTS (SELECT 1 FROM Reviews WHERE ContractId = @ContractId AND ReviewerId = @ReviewerId)
    BEGIN
        SELECT 0 AS Success, 'Ya calificaste este contrato' AS Message;
        RETURN;
    END

    DECLARE @ReviewId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO Reviews (Id, ContractId, ReviewerId, ReviewedId, Rating, Comment, Quality, Punctuality, Communication, Professionalism, Compliance)
    VALUES (@ReviewId, @ContractId, @ReviewerId, @ReviewedId, @Rating, @Comment, @Quality, @Punctuality, @Communication, @Professionalism, @Compliance);

    -- Actualizar promedio del usuario calificado
    DECLARE @AvgRating DECIMAL(3,2);
    DECLARE @TotalReviews INT;

    SELECT @AvgRating = AVG(Rating), @TotalReviews = COUNT(*)
    FROM Reviews WHERE ReviewedId = @ReviewedId AND Visible = 1;

    UPDATE WorkerProfiles
    SET AverageRating = COALESCE(@AvgRating, 0), TotalReviews = @TotalReviews, UpdatedAt = GETUTCDATE()
    WHERE UserId = @ReviewedId;

    UPDATE EmployerProfiles
    SET AverageRating = COALESCE(@AvgRating, 0), TotalReviews = @TotalReviews, UpdatedAt = GETUTCDATE()
    WHERE UserId = @ReviewedId;

    -- Notificar
    DECLARE @ReviewerName NVARCHAR(200);
    SELECT @ReviewerName = FirstName + ' ' + LastName FROM Users WHERE Id = @ReviewerId;

    INSERT INTO Notifications (UserId, Type, Title, Body, Data)
    VALUES (@ReviewedId, 'NEW_REVIEW', 'Nueva calificación',
            @ReviewerName + ' te calificó con ' + CAST(@Rating AS NVARCHAR) + ' estrellas',
            '{"reviewId":"' + CAST(@ReviewId AS NVARCHAR(36)) + '","contractId":"' + CAST(@ContractId AS NVARCHAR(36)) + '"}');

    SELECT 1 AS Success, 'Calificación enviada' AS Message, @ReviewId AS ReviewId;
END
GO

-- SP: Obtener reseñas de un usuario
CREATE OR ALTER PROCEDURE sp_Reviews_GetByUser
    @UserId     UNIQUEIDENTIFIER,
    @Page       INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        r.Id, r.Rating, r.Comment, r.Quality, r.Punctuality,
        r.Communication, r.Professionalism, r.Compliance, r.CreatedAt,
        u.FirstName AS ReviewerFirstName, u.LastName AS ReviewerLastName, u.Avatar AS ReviewerAvatar,
        j.Title AS JobTitle
    FROM Reviews r
    INNER JOIN Users u ON r.ReviewerId = u.Id
    INNER JOIN Contracts ct ON r.ContractId = ct.Id
    INNER JOIN Jobs j ON ct.JobId = j.Id
    WHERE r.ReviewedId = @UserId AND r.Visible = 1
    ORDER BY r.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 12: STORED PROCEDURES - FAVORITOS
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Agregar favorito
CREATE OR ALTER PROCEDURE sp_Favorites_Add
    @UserId UNIQUEIDENTIFIER,
    @JobId  UNIQUEIDENTIFIER,
    @Type   NVARCHAR(20) = 'JOB'
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Favorites WHERE UserId = @UserId AND JobId = @JobId AND Type = @Type)
    BEGIN
        SELECT 1 AS Success, 'Ya está en favoritos' AS Message;
        RETURN;
    END

    INSERT INTO Favorites (UserId, JobId, Type)
    VALUES (@UserId, @JobId, @Type);

    SELECT 1 AS Success, 'Agregado a favoritos' AS Message;
END
GO

-- SP: Quitar favorito
CREATE OR ALTER PROCEDURE sp_Favorites_Remove
    @UserId UNIQUEIDENTIFIER,
    @JobId  UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Favorites WHERE UserId = @UserId AND JobId = @JobId;
    SELECT 1 AS Success, 'Eliminado de favoritos' AS Message;
END
GO

-- SP: Obtener mis favoritos
CREATE OR ALTER PROCEDURE sp_Favorites_GetMine
    @UserId     UNIQUEIDENTIFIER,
    @Page       INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        f.Id AS FavoriteId, f.CreatedAt AS FavoritedAt,
        j.Id AS JobId, j.Title, j.Status, j.Modality, j.BudgetMin, j.BudgetMax,
        j.BudgetFixed, j.IsUrgent, j.Address, j.PublishedAt,
        c.Name AS CategoryName, c.Icon AS CategoryIcon,
        u.FirstName AS PublisherFirstName, u.LastName AS PublisherLastName
    FROM Favorites f
    INNER JOIN Jobs j ON f.JobId = j.Id
    INNER JOIN Categories c ON j.CategoryId = c.Id
    INNER JOIN Users u ON j.PublisherId = u.Id
    WHERE f.UserId = @UserId AND f.Type = 'JOB' AND j.DeletedAt IS NULL
    ORDER BY f.CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 13: STORED PROCEDURES - CATEGORÍAS
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Obtener todas las categorías activas
CREATE OR ALTER PROCEDURE sp_Categories_GetAll
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name, Description, Icon, Image, SortOrder
    FROM Categories
    WHERE Active = 1
    ORDER BY SortOrder;
END
GO

-- SP: Obtener subcategorías de una categoría
CREATE OR ALTER PROCEDURE sp_Categories_GetSubcategories
    @CategoryId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Name, SortOrder
    FROM Subcategories
    WHERE CategoryId = @CategoryId AND Active = 1
    ORDER BY SortOrder;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 14: STORED PROCEDURES - REPORTES Y VERIFICACIÓN
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Crear reporte
CREATE OR ALTER PROCEDURE sp_Reports_Create
    @ReporterId     UNIQUEIDENTIFIER,
    @ReportedUserId UNIQUEIDENTIFIER = NULL,
    @JobId          UNIQUEIDENTIFIER = NULL,
    @Reason         NVARCHAR(30),
    @Description    NVARCHAR(2000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ReportId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO Reports (Id, ReporterId, ReportedUserId, JobId, Reason, Description)
    VALUES (@ReportId, @ReporterId, @ReportedUserId, @JobId, @Reason, @Description);

    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId)
    VALUES (@ReporterId, 'CREATE_REPORT', 'REPORT', @ReportId);

    SELECT 1 AS Success, 'Reporte enviado. Lo revisaremos pronto.' AS Message;
END
GO

-- SP: Subir documento de verificación
CREATE OR ALTER PROCEDURE sp_Documents_Upload
    @UserId UNIQUEIDENTIFIER,
    @Type   NVARCHAR(50),
    @Url    NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    -- Si ya tiene un documento de ese tipo pendiente o aprobado, no duplicar
    IF EXISTS (SELECT 1 FROM Documents WHERE UserId = @UserId AND Type = @Type AND Status IN ('PENDING', 'APPROVED'))
    BEGIN
        SELECT 0 AS Success, 'Ya tienes un documento de este tipo en proceso' AS Message;
        RETURN;
    END

    INSERT INTO Documents (UserId, Type, Url)
    VALUES (@UserId, @Type, @Url);

    SELECT 1 AS Success, 'Documento subido, en revisión' AS Message;
END
GO

-- SP: Obtener estado de verificaciones de un usuario
CREATE OR ALTER PROCEDURE sp_Documents_GetStatus
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, Type, Status, Note, ReviewedAt, CreatedAt
    FROM Documents
    WHERE UserId = @UserId
    ORDER BY CreatedAt DESC;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 15: STORED PROCEDURES - DISPOSITIVOS (PUSH)
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Registrar dispositivo para push
CREATE OR ALTER PROCEDURE sp_Devices_Register
    @UserId     UNIQUEIDENTIFIER,
    @FcmToken   NVARCHAR(500),
    @Platform   NVARCHAR(20),
    @DeviceName NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Upsert: si ya existe el token, actualizar
    IF EXISTS (SELECT 1 FROM Devices WHERE UserId = @UserId AND FcmToken = @FcmToken)
    BEGIN
        UPDATE Devices SET Active = 1, Platform = @Platform, DeviceName = @DeviceName, UpdatedAt = GETUTCDATE()
        WHERE UserId = @UserId AND FcmToken = @FcmToken;
    END
    ELSE
    BEGIN
        INSERT INTO Devices (UserId, FcmToken, Platform, DeviceName)
        VALUES (@UserId, @FcmToken, @Platform, @DeviceName);
    END

    SELECT 1 AS Success;
END
GO

-- SP: Obtener tokens de push de un usuario (para enviar notificaciones)
CREATE OR ALTER PROCEDURE sp_Devices_GetTokens
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT FcmToken, Platform FROM Devices WHERE UserId = @UserId AND Active = 1;
END
GO

-- SP: Desactivar dispositivo (logout)
CREATE OR ALTER PROCEDURE sp_Devices_Deactivate
    @UserId     UNIQUEIDENTIFIER,
    @FcmToken   NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Devices SET Active = 0, UpdatedAt = GETUTCDATE()
    WHERE UserId = @UserId AND FcmToken = @FcmToken;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 16: STORED PROCEDURES - USUARIOS BLOQUEADOS
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Bloquear usuario
CREATE OR ALTER PROCEDURE sp_BlockedUsers_Block
    @UserId         UNIQUEIDENTIFIER,
    @BlockedUserId  UNIQUEIDENTIFIER,
    @Reason         NVARCHAR(200) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @UserId = @BlockedUserId
    BEGIN
        SELECT 0 AS Success, 'No puedes bloquearte a ti mismo' AS Message;
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM BlockedUsers WHERE UserId = @UserId AND BlockedUserId = @BlockedUserId)
    BEGIN
        INSERT INTO BlockedUsers (UserId, BlockedUserId, Reason)
        VALUES (@UserId, @BlockedUserId, @Reason);
    END

    SELECT 1 AS Success, 'Usuario bloqueado' AS Message;
END
GO

-- SP: Desbloquear usuario
CREATE OR ALTER PROCEDURE sp_BlockedUsers_Unblock
    @UserId         UNIQUEIDENTIFIER,
    @BlockedUserId  UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM BlockedUsers WHERE UserId = @UserId AND BlockedUserId = @BlockedUserId;
    SELECT 1 AS Success, 'Usuario desbloqueado' AS Message;
END
GO

-- SP: Listar bloqueados
CREATE OR ALTER PROCEDURE sp_BlockedUsers_GetList
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        bu.BlockedUserId, bu.Reason, bu.CreatedAt,
        u.FirstName, u.LastName, u.Avatar
    FROM BlockedUsers bu
    INNER JOIN Users u ON bu.BlockedUserId = u.Id
    WHERE bu.UserId = @UserId;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 17: STORED PROCEDURES - CONFIGURACIÓN DE NOTIFICACIONES
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Obtener configuración
CREATE OR ALTER PROCEDURE sp_NotifSettings_Get
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT * FROM NotificationSettings WHERE UserId = @UserId;
END
GO

-- SP: Actualizar configuración
CREATE OR ALTER PROCEDURE sp_NotifSettings_Update
    @UserId             UNIQUEIDENTIFIER,
    @PushEnabled        BIT = NULL,
    @EmailEnabled       BIT = NULL,
    @NewApplications    BIT = NULL,
    @ApplicationUpdates BIT = NULL,
    @NewMessages        BIT = NULL,
    @JobReminders       BIT = NULL,
    @Reviews            BIT = NULL,
    @Promotions         BIT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM NotificationSettings WHERE UserId = @UserId)
        INSERT INTO NotificationSettings (UserId) VALUES (@UserId);

    UPDATE NotificationSettings
    SET PushEnabled = COALESCE(@PushEnabled, PushEnabled),
        EmailEnabled = COALESCE(@EmailEnabled, EmailEnabled),
        NewApplications = COALESCE(@NewApplications, NewApplications),
        ApplicationUpdates = COALESCE(@ApplicationUpdates, ApplicationUpdates),
        NewMessages = COALESCE(@NewMessages, NewMessages),
        JobReminders = COALESCE(@JobReminders, JobReminders),
        Reviews = COALESCE(@Reviews, Reviews),
        Promotions = COALESCE(@Promotions, Promotions),
        UpdatedAt = GETUTCDATE()
    WHERE UserId = @UserId;

    SELECT 1 AS Success, 'Configuración actualizada' AS Message;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 18: STORED PROCEDURES - MANTENIMIENTO Y ADMINISTRACIÓN
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Limpiar tokens expirados (ejecutar con SQL Agent Job diariamente)
CREATE OR ALTER PROCEDURE sp_Maintenance_CleanExpiredTokens
AS
BEGIN
    SET NOCOUNT ON;

    DELETE FROM RefreshTokens WHERE ExpiresAt < GETUTCDATE() OR Revoked = 1;

    DECLARE @Deleted INT = @@ROWCOUNT;
    SELECT @Deleted AS TokensDeleted;
END
GO

-- SP: Expirar trabajos viejos sin actividad (ejecutar diariamente)
CREATE OR ALTER PROCEDURE sp_Maintenance_ExpireStaleJobs
AS
BEGIN
    SET NOCOUNT ON;

    -- Expirar trabajos con deadline pasado
    UPDATE Jobs SET Status = 'EXPIRED', UpdatedAt = GETUTCDATE()
    WHERE Status = 'PUBLISHED' AND ApplyDeadline IS NOT NULL AND ApplyDeadline < GETUTCDATE();

    -- Expirar trabajos de más de 30 días sin postulaciones
    UPDATE Jobs SET Status = 'EXPIRED', UpdatedAt = GETUTCDATE()
    WHERE Status = 'PUBLISHED'
      AND ApplyDeadline IS NULL
      AND PublishedAt < DATEADD(DAY, -30, GETUTCDATE())
      AND ApplicantsCount = 0;

    SELECT @@ROWCOUNT AS JobsExpired;
END
GO

-- SP: Dashboard de admin - estadísticas generales
CREATE OR ALTER PROCEDURE sp_Admin_GetStats
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        (SELECT COUNT(*) FROM Users WHERE DeletedAt IS NULL) AS TotalUsers,
        (SELECT COUNT(*) FROM Users WHERE Status = 'ACTIVE') AS ActiveUsers,
        (SELECT COUNT(*) FROM Users WHERE CreatedAt >= DATEADD(DAY, -7, GETUTCDATE())) AS NewUsersWeek,
        (SELECT COUNT(*) FROM Jobs WHERE DeletedAt IS NULL) AS TotalJobs,
        (SELECT COUNT(*) FROM Jobs WHERE Status = 'PUBLISHED') AS PublishedJobs,
        (SELECT COUNT(*) FROM Jobs WHERE CreatedAt >= DATEADD(DAY, -7, GETUTCDATE())) AS NewJobsWeek,
        (SELECT COUNT(*) FROM Applications) AS TotalApplications,
        (SELECT COUNT(*) FROM Contracts WHERE Status = 'COMPLETED') AS CompletedContracts,
        (SELECT COUNT(*) FROM Reports WHERE Status = 'OPEN') AS OpenReports,
        (SELECT COUNT(*) FROM Documents WHERE Status = 'PENDING') AS PendingVerifications;
END
GO

-- SP: Buscar usuarios (admin)
CREATE OR ALTER PROCEDURE sp_Admin_SearchUsers
    @Search     NVARCHAR(100) = NULL,
    @Status     NVARCHAR(20) = NULL,
    @Role       NVARCHAR(20) = NULL,
    @Page       INT = 1,
    @PageSize   INT = 50
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        Id, Email, Phone, FirstName, LastName, Avatar,
        Role, UserType, Status, EmailVerified, PhoneVerified,
        City, LastLoginAt, CreatedAt
    FROM Users
    WHERE DeletedAt IS NULL
      AND (@Search IS NULL OR Email LIKE '%' + @Search + '%'
           OR FirstName LIKE '%' + @Search + '%' OR LastName LIKE '%' + @Search + '%'
           OR Phone LIKE '%' + @Search + '%')
      AND (@Status IS NULL OR Status = @Status)
      AND (@Role IS NULL OR Role = @Role)
    ORDER BY CreatedAt DESC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 19: TRIGGERS
-- ─────────────────────────────────────────────────────────────────────────────

-- Trigger: Actualizar UpdatedAt en Users
CREATE OR ALTER TRIGGER trg_Users_UpdatedAt ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE u SET UpdatedAt = GETUTCDATE()
        FROM Users u INNER JOIN inserted i ON u.Id = i.Id;
    END
END
GO

-- Trigger: Actualizar UpdatedAt en Jobs
CREATE OR ALTER TRIGGER trg_Jobs_UpdatedAt ON Jobs
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF NOT UPDATE(UpdatedAt)
    BEGIN
        UPDATE j SET UpdatedAt = GETUTCDATE()
        FROM Jobs j INNER JOIN inserted i ON j.Id = i.Id;
    END
END
GO

-- Trigger: Incrementar/decrementar ApplicantsCount en Jobs al insertar Application
CREATE OR ALTER TRIGGER trg_Applications_CountInsert ON Applications
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE j SET ApplicantsCount = ApplicantsCount + counts.cnt
    FROM Jobs j
    INNER JOIN (SELECT JobId, COUNT(*) AS cnt FROM inserted GROUP BY JobId) counts ON j.Id = counts.JobId;
END
GO

-- Trigger: Decrementar si se retira/cancela postulación
CREATE OR ALTER TRIGGER trg_Applications_CountUpdate ON Applications
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    IF UPDATE(Status)
    BEGIN
        -- Restar cuando pasan a WITHDRAWN o CANCELLED
        UPDATE j SET ApplicantsCount = CASE WHEN ApplicantsCount > 0 THEN ApplicantsCount - 1 ELSE 0 END
        FROM Jobs j
        INNER JOIN inserted i ON j.Id = i.JobId
        INNER JOIN deleted d ON i.Id = d.Id
        WHERE i.Status IN ('WITHDRAWN', 'CANCELLED')
          AND d.Status NOT IN ('WITHDRAWN', 'CANCELLED');
    END
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 20: DATOS INICIALES (SEED)
-- ─────────────────────────────────────────────────────────────────────────────

-- Categorías de servicios
IF NOT EXISTS (SELECT 1 FROM Categories WHERE Name = 'Plomería')
BEGIN
    INSERT INTO Categories (Name, Description, Icon, SortOrder) VALUES
    (N'Plomería',       N'Instalación y reparación de tuberías, grifos, sanitarios', 'plumbing', 1),
    (N'Albañilería',    N'Construcción, remodelación, acabados en concreto',         'construction', 2),
    (N'Electricidad',   N'Instalaciones eléctricas, reparaciones, cableado',         'electrical_services', 3),
    (N'Pintura',        N'Pintura interior y exterior, acabados decorativos',        'format_paint', 4),
    (N'Carpintería',    N'Muebles a medida, reparación de madera, closets',          'carpenter', 5),
    (N'Cerrajería',     N'Apertura, cambio de chapas, duplicado de llaves',          'lock', 6),
    (N'Limpieza',       N'Limpieza profunda, mantenimiento de hogares y oficinas',   'cleaning_services', 7),
    (N'Jardinería',     N'Diseño de jardines, poda, mantenimiento de áreas verdes',  'grass', 8),
    (N'Mecánica',       N'Reparación automotriz, mantenimiento vehicular',           'build', 9),
    (N'Refrigeración',  N'Instalación y reparación de aires acondicionados',         'ac_unit', 10),
    (N'Tecnología',     N'Soporte técnico, redes, computadoras',                     'computer', 11),
    (N'Transporte',     N'Fletes, envíos, transporte de carga',                      'local_shipping', 12),
    (N'Mudanzas',       N'Servicio de mudanza completo, embalaje',                   'move_to_inbox', 13),
    (N'Cocina',         N'Catering, cocina a domicilio, eventos',                    'restaurant', 14),
    (N'Seguridad',      N'Vigilancia, instalación de cámaras, alarmas',              'security', 15),
    (N'Otros',          N'Otros servicios no categorizados',                         'more_horiz', 16);
END
GO

-- Usuario administrador
-- NOTA: Reemplazar PasswordHash con un hash real generado con bcrypt/argon2
IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = 'admin@laboraya.com')
BEGIN
    DECLARE @AdminId UNIQUEIDENTIFIER = NEWID();

    INSERT INTO Users (Id, Email, FirstName, LastName, PasswordHash, Role, UserType, EmailVerified, PhoneVerified, City)
    VALUES (@AdminId, N'admin@laboraya.com', N'Admin', N'LaboraYa',
            N'$2b$12$CAMBIAR_POR_HASH_REAL_GENERADO_CON_BCRYPT',
            'SUPER_ADMIN', 'BOTH', 1, 1, N'Lima');

    INSERT INTO NotificationSettings (UserId) VALUES (@AdminId);
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 21: VISTAS ÚTILES PARA EL API
-- ─────────────────────────────────────────────────────────────────────────────

-- Vista: Feed de trabajos publicados
CREATE OR ALTER VIEW vw_JobsFeed AS
SELECT
    j.Id, j.Title, j.Description, j.Address, j.Latitude, j.Longitude,
    j.Modality, j.BudgetMin, j.BudgetMax, j.BudgetFixed, j.Currency,
    j.IsUrgent, j.IsRemote, j.Status, j.Duration, j.WorkersNeeded,
    j.Materials, j.ApplicantsCount, j.ViewsCount, j.PublishedAt, j.CreatedAt,
    c.Id AS CategoryId, c.Name AS CategoryName, c.Icon AS CategoryIcon,
    u.Id AS PublisherId, u.FirstName AS PublisherFirstName,
    u.LastName AS PublisherLastName, u.Avatar AS PublisherAvatar
FROM Jobs j
INNER JOIN Categories c ON j.CategoryId = c.Id
INNER JOIN Users u ON j.PublisherId = u.Id
WHERE j.Status = 'PUBLISHED' AND j.DeletedAt IS NULL AND u.Status = 'ACTIVE';
GO

-- Vista: Resumen de usuario
CREATE OR ALTER VIEW vw_UserSummary AS
SELECT
    u.Id, u.Email, u.FirstName, u.LastName, u.Avatar,
    u.UserType, u.City, u.Status, u.CreatedAt,
    COALESCE(wp.AverageRating, ep.AverageRating, 0) AS Rating,
    COALESCE(wp.TotalReviews, ep.TotalReviews, 0) AS TotalReviews,
    COALESCE(wp.CompletedJobs, 0) AS CompletedJobs,
    COALESCE(ep.CompletedHires, 0) AS CompletedHires,
    COALESCE(ep.Verified, 0) AS IsVerified
FROM Users u
LEFT JOIN WorkerProfiles wp ON u.Id = wp.UserId
LEFT JOIN EmployerProfiles ep ON u.Id = ep.UserId
WHERE u.DeletedAt IS NULL;
GO

-- Vista: Conteo de no leídos por usuario
CREATE OR ALTER VIEW vw_UnreadCounts AS
SELECT
    u.Id AS UserId,
    (SELECT COUNT(*) FROM Notifications n WHERE n.UserId = u.Id AND n.IsRead = 0) AS UnreadNotifications,
    (SELECT COALESCE(SUM(sub.UnreadCount), 0) FROM (
        SELECT
            (SELECT COUNT(*) FROM Messages m
             WHERE m.ConversationId = cp.ConversationId
             AND m.SenderId != u.Id
             AND m.CreatedAt > COALESCE(cp.LastReadAt, '1900-01-01')) AS UnreadCount
        FROM ConversationParticipants cp
        WHERE cp.UserId = u.Id
    ) sub) AS UnreadMessages
FROM Users u
WHERE u.DeletedAt IS NULL;
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 22: STORED PROCEDURES ADICIONALES - UBICACIONES Y BÚSQUEDA GEOGRÁFICA
-- ─────────────────────────────────────────────────────────────────────────────

-- SP: Guardar ubicación
CREATE OR ALTER PROCEDURE sp_Locations_Save
    @UserId     UNIQUEIDENTIFIER,
    @Label      NVARCHAR(100),
    @Address    NVARCHAR(300),
    @Latitude   FLOAT,
    @Longitude  FLOAT,
    @IsDefault  BIT = 0
AS
BEGIN
    SET NOCOUNT ON;

    -- Si es default, quitar default de las demás
    IF @IsDefault = 1
        UPDATE SavedLocations SET IsDefault = 0 WHERE UserId = @UserId;

    INSERT INTO SavedLocations (UserId, Label, Address, Latitude, Longitude, IsDefault)
    VALUES (@UserId, @Label, @Address, @Latitude, @Longitude, @IsDefault);

    SELECT 1 AS Success, 'Ubicación guardada' AS Message;
END
GO

-- SP: Obtener ubicaciones guardadas
CREATE OR ALTER PROCEDURE sp_Locations_GetMine
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;
    SELECT Id, Label, Address, Latitude, Longitude, IsDefault, CreatedAt
    FROM SavedLocations WHERE UserId = @UserId ORDER BY IsDefault DESC, CreatedAt DESC;
END
GO

-- SP: Buscar trabajos cercanos (por radio en km)
CREATE OR ALTER PROCEDURE sp_Jobs_GetNearby
    @Latitude   FLOAT,
    @Longitude  FLOAT,
    @RadiusKm   FLOAT = 10,
    @Page       INT = 1,
    @PageSize   INT = 20
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PageSize;

    SELECT
        j.Id, j.Title, j.Address, j.Latitude, j.Longitude,
        j.Modality, j.BudgetMin, j.BudgetMax, j.BudgetFixed,
        j.IsUrgent, j.PublishedAt,
        c.Name AS CategoryName, c.Icon AS CategoryIcon,
        u.FirstName AS PublisherFirstName, u.LastName AS PublisherLastName,
        -- Distancia en km (fórmula de Haversine)
        (6371 * ACOS(
            COS(RADIANS(@Latitude)) * COS(RADIANS(j.Latitude)) *
            COS(RADIANS(j.Longitude) - RADIANS(@Longitude)) +
            SIN(RADIANS(@Latitude)) * SIN(RADIANS(j.Latitude))
        )) AS DistanceKm
    FROM Jobs j
    INNER JOIN Categories c ON j.CategoryId = c.Id
    INNER JOIN Users u ON j.PublisherId = u.Id
    WHERE j.Status = 'PUBLISHED'
      AND j.DeletedAt IS NULL
      AND j.Latitude IS NOT NULL
      AND j.Longitude IS NOT NULL
      AND (6371 * ACOS(
          COS(RADIANS(@Latitude)) * COS(RADIANS(j.Latitude)) *
          COS(RADIANS(j.Longitude) - RADIANS(@Longitude)) +
          SIN(RADIANS(@Latitude)) * SIN(RADIANS(j.Latitude))
      )) <= @RadiusKm
    ORDER BY DistanceKm ASC
    OFFSET @Offset ROWS FETCH NEXT @PageSize ROWS ONLY;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 23: SP PARA ELIMINAR CUENTA (GDPR/PROTECCIÓN DE DATOS)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE sp_Users_DeleteAccount
    @UserId UNIQUEIDENTIFIER
AS
BEGIN
    SET NOCOUNT ON;

    -- Soft delete: anonimizar datos personales pero mantener integridad
    UPDATE Users
    SET Status = 'DELETED',
        Email = 'deleted_' + CAST(@UserId AS NVARCHAR(36)) + '@removed.com',
        Phone = NULL,
        FirstName = 'Usuario',
        LastName = 'Eliminado',
        Avatar = NULL,
        Bio = NULL,
        DeletedAt = GETUTCDATE(),
        UpdatedAt = GETUTCDATE()
    WHERE Id = @UserId;

    -- Revocar todos los tokens
    UPDATE RefreshTokens SET Revoked = 1, RevokedAt = GETUTCDATE() WHERE UserId = @UserId AND Revoked = 0;

    -- Desactivar dispositivos
    UPDATE Devices SET Active = 0 WHERE UserId = @UserId;

    -- Cancelar trabajos en draft
    UPDATE Jobs SET Status = 'CANCELLED', DeletedAt = GETUTCDATE(), UpdatedAt = GETUTCDATE()
    WHERE PublisherId = @UserId AND Status = 'DRAFT';

    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId)
    VALUES (@UserId, 'DELETE_ACCOUNT', 'USER', @UserId);

    SELECT 1 AS Success, 'Cuenta eliminada correctamente' AS Message;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 24: SP PARA CAMBIAR CONTRASEÑA
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR ALTER PROCEDURE sp_Users_ChangePassword
    @UserId         UNIQUEIDENTIFIER,
    @NewPasswordHash NVARCHAR(500)
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Users SET PasswordHash = @NewPasswordHash, UpdatedAt = GETUTCDATE()
    WHERE Id = @UserId AND DeletedAt IS NULL;

    -- Revocar todos los tokens (forzar re-login en otros dispositivos)
    UPDATE RefreshTokens SET Revoked = 1, RevokedAt = GETUTCDATE()
    WHERE UserId = @UserId AND Revoked = 0;

    INSERT INTO ActivityLog (UserId, Action, Entity, EntityId)
    VALUES (@UserId, 'CHANGE_PASSWORD', 'USER', @UserId);

    SELECT 1 AS Success, 'Contraseña actualizada. Debes iniciar sesión nuevamente.' AS Message;
END
GO

-- ─────────────────────────────────────────────────────────────────────────────
-- PASO 25: PERMISOS Y SEGURIDAD
-- ─────────────────────────────────────────────────────────────────────────────
-- NOTA: Descomentar y ajustar según tu configuración de servidor.
-- Crear un login/user específico para que tu API se conecte (NUNCA usar SA).

/*
-- Crear login para la API
CREATE LOGIN LaboraYaApi WITH PASSWORD = 'Tu_Password_Seguro_123!';
GO

USE LaboraYa;
GO

-- Crear usuario en la base de datos
CREATE USER LaboraYaApi FOR LOGIN LaboraYaApi;
GO

-- Dar permisos de ejecución en stored procedures (NO acceso directo a tablas)
GRANT EXECUTE ON SCHEMA::dbo TO LaboraYaApi;
GO

-- Si necesitas que lea vistas también:
GRANT SELECT ON vw_JobsFeed TO LaboraYaApi;
GRANT SELECT ON vw_UserSummary TO LaboraYaApi;
GRANT SELECT ON vw_UnreadCounts TO LaboraYaApi;
GO
*/

-- ─────────────────────────────────────────────────────────────────────────────
-- FIN DEL SCRIPT
-- ─────────────────────────────────────────────────────────────────────────────
-- ┌──────────────────────────────────────────────────────────────────────────┐
-- │ RESUMEN DE OBJETOS CREADOS                                                │
-- ├──────────────────────────────────────────────────────────────────────────┤
-- │                                                                            │
-- │  TABLAS (19):                                                              │
-- │    Users, WorkerProfiles, EmployerProfiles, Categories, Subcategories,    │
-- │    Jobs, JobImages, WorkerSkills, Applications, Contracts,                 │
-- │    Conversations, ConversationParticipants, Messages, Reviews,             │
-- │    Notifications, Favorites, Reports, Documents, RefreshTokens,           │
-- │    Devices, ActivityLog, NotificationSettings, BlockedUsers,               │
-- │    SavedLocations                                                          │
-- │                                                                            │
-- │  STORED PROCEDURES (40+):                                                  │
-- │    Auth: Register, Login, LoginSuccess, LoginFailed, SaveRefreshToken,    │
-- │          RefreshToken, RevokeToken, RevokeAllTokens                        │
-- │    Users: GetProfile, UpdateProfile, UpdateWorkerProfile,                  │
-- │           DeleteAccount, ChangePassword                                    │
-- │    Jobs: Create, GetFeed, GetById, GetMine, Update, Delete, GetNearby     │
-- │    Applications: Create, GetByJob, Accept, Reject, GetMine                │
-- │    Contracts: UpdateStatus, GetMine                                        │
-- │    Chat: GetOrCreateConversation, SendMessage, GetConversations,           │
-- │          GetMessages                                                       │
-- │    Notifications: Get, UnreadCount, MarkRead, MarkAllRead                 │
-- │    Reviews: Create, GetByUser                                              │
-- │    Favorites: Add, Remove, GetMine                                         │
-- │    Categories: GetAll, GetSubcategories                                    │
-- │    Reports: Create                                                         │
-- │    Documents: Upload, GetStatus                                            │
-- │    Devices: Register, GetTokens, Deactivate                               │
-- │    BlockedUsers: Block, Unblock, GetList                                   │
-- │    NotifSettings: Get, Update                                              │
-- │    Locations: Save, GetMine                                                │
-- │    Maintenance: CleanExpiredTokens, ExpireStaleJobs                        │
-- │    Admin: GetStats, SearchUsers                                            │
-- │                                                                            │
-- │  VISTAS (3): vw_JobsFeed, vw_UserSummary, vw_UnreadCounts                │
-- │                                                                            │
-- │  TRIGGERS (4): trg_Users_UpdatedAt, trg_Jobs_UpdatedAt,                   │
-- │                trg_Applications_CountInsert, trg_Applications_CountUpdate  │
-- │                                                                            │
-- │  ÍNDICES (30+): Optimizados para las queries más frecuentes               │
-- │                                                                            │
-- │  DATOS SEED: 16 categorías + 1 usuario administrador                      │
-- │                                                                            │
-- └──────────────────────────────────────────────────────────────────────────┘
-- ============================================================================
PRINT '✅ Base de datos LaboraYa creada exitosamente con todas las tablas, SPs e índices.';
GO
