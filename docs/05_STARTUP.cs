// ============================================================================
// LABORAYA API - PROGRAM.CS (ASP.NET Core 8 Minimal API + Controllers)
// ============================================================================
// Este es el punto de entrada. Configura SQL Server + Dapper + JWT + CORS.
// Proyecto tipo: dotnet new webapi -n LaboraYa.API
// ============================================================================
// NuGets necesarios (copiar al .csproj o instalar con dotnet add package):
//   - Dapper
//   - Microsoft.Data.SqlClient
//   - BCrypt.Net-Next
//   - Microsoft.AspNetCore.Authentication.JwtBearer
//   - Swashbuckle.AspNetCore
//   - Microsoft.AspNetCore.SignalR
// ============================================================================

using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using LaboraYa.API.Interfaces;
using LaboraYa.API.Services;

var builder = WebApplication.CreateBuilder(args);

// ─────────────────────────────────────────────────────────────────────────────
// 1. CONEXIÓN A SQL SERVER
// ─────────────────────────────────────────────────────────────────────────────
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection")!;
builder.Services.AddSingleton<IDbConnectionFactory>(
    new SqlServerConnectionFactory(connectionString));

// ─────────────────────────────────────────────────────────────────────────────
// 2. AUTENTICACIÓN JWT
// ─────────────────────────────────────────────────────────────────────────────
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"]!)),
            ValidateIssuer = false,
            ValidateAudience = false,
            ClockSkew = TimeSpan.Zero
        };
    });
builder.Services.AddAuthorization();

// ─────────────────────────────────────────────────────────────────────────────
// 3. CORS (permitir Flutter app)
// ─────────────────────────────────────────────────────────────────────────────
builder.Services.AddCors(options =>
{
    options.AddPolicy("LaboraYaPolicy", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader());
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. INYECCIÓN DE SERVICIOS (cada service llama a los SPs de SQL Server)
// ─────────────────────────────────────────────────────────────────────────────
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IJobService, JobService>();
builder.Services.AddScoped<IApplicationService, ApplicationService>();
builder.Services.AddScoped<IContractService, ContractService>();
builder.Services.AddScoped<IChatService, ChatService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IReviewService, ReviewService>();
builder.Services.AddScoped<IFavoriteService, FavoriteService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IReportService, ReportService>();
builder.Services.AddScoped<IDocumentService, DocumentService>();
builder.Services.AddScoped<IDeviceService, DeviceService>();
builder.Services.AddScoped<IBlockedUserService, BlockedUserService>();
builder.Services.AddScoped<INotificationSettingsService, NotificationSettingsService>();
builder.Services.AddScoped<ILocationService, LocationService>();

// ─────────────────────────────────────────────────────────────────────────────
// 5. CONTROLLERS + SWAGGER
// ─────────────────────────────────────────────────────────────────────────────
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "LaboraYa API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new Microsoft.OpenApi.Models.OpenApiSecurityScheme
    {
        Description = "Ingresa tu token JWT: Bearer {token}",
        Name = "Authorization",
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new Microsoft.OpenApi.Models.OpenApiSecurityRequirement
    {
        {
            new Microsoft.OpenApi.Models.OpenApiSecurityScheme
            {
                Reference = new Microsoft.OpenApi.Models.OpenApiReference
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// 6. SignalR (para chat en tiempo real)
builder.Services.AddSignalR();

// ─────────────────────────────────────────────────────────────────────────────
// BUILD & CONFIGURE PIPELINE
// ─────────────────────────────────────────────────────────────────────────────
var app = builder.Build();

// Swagger (siempre activo para desarrollo, en producción puedes condicionar)
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "LaboraYa API v1");
    c.RoutePrefix = string.Empty; // Swagger en la raíz
});

app.UseCors("LaboraYaPolicy");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// Hub de SignalR para chat
// app.MapHub<ChatHub>("/chat");

app.Run();

// ============================================================================
// APPSETTINGS.JSON - Copiar este contenido en tu appsettings.json
// ============================================================================
/*
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=SAPSERVER;Database=LaboraYa;User Id=LaboraYaApi;Password=TU_PASSWORD_SEGURO;TrustServerCertificate=True;Encrypt=False;"
  },
  "Jwt": {
    "Secret": "clave-secreta-minimo-32-caracteres-cambiar-esto-por-algo-seguro-2024",
    "ExpiresInMinutes": 15,
    "RefreshExpiresInDays": 7
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
*/

// ============================================================================
// .CSPROJ - NuGets necesarios (copiar dentro de <ItemGroup>)
// ============================================================================
/*
<ItemGroup>
  <PackageReference Include="Dapper" Version="2.1.35" />
  <PackageReference Include="Microsoft.Data.SqlClient" Version="5.2.1" />
  <PackageReference Include="BCrypt.Net-Next" Version="4.0.3" />
  <PackageReference Include="Microsoft.AspNetCore.Authentication.JwtBearer" Version="8.0.8" />
  <PackageReference Include="Swashbuckle.AspNetCore" Version="6.7.0" />
  <PackageReference Include="Microsoft.AspNetCore.SignalR" Version="1.1.0" />
</ItemGroup>
*/

// ============================================================================
// ESTRUCTURA DE CARPETAS DEL PROYECTO:
// ============================================================================
/*
LaboraYa.API/
├── Controllers/
│   ├── AuthController.cs
│   ├── UsersController.cs
│   ├── JobsController.cs
│   ├── ApplicationsController.cs
│   ├── ContractsController.cs
│   ├── ChatsController.cs
│   ├── NotificationsController.cs
│   ├── ReviewsController.cs
│   ├── FavoritesController.cs
│   ├── CategoriesController.cs
│   ├── ReportsController.cs
│   ├── VerificationsController.cs
│   ├── DevicesController.cs
│   └── SettingsController.cs
├── DTOs/
│   ├── AuthDtos.cs
│   ├── UserDtos.cs
│   ├── JobDtos.cs
│   ├── ApplicationDtos.cs
│   ├── ChatDtos.cs
│   ├── ReviewDtos.cs
│   └── CommonDtos.cs
├── Entities/
│   ├── UserEntity.cs
│   ├── JobEntity.cs
│   ├── ApplicationEntity.cs
│   ├── ContractEntity.cs
│   ├── ConversationEntity.cs
│   ├── MessageEntity.cs
│   ├── ReviewEntity.cs
│   ├── NotificationEntity.cs
│   ├── FavoriteEntity.cs
│   ├── CategoryEntity.cs
│   └── SpResult.cs
├── Enums/
│   └── LaboraYaEnums.cs
├── Interfaces/
│   ├── IAuthService.cs
│   ├── IUserService.cs
│   ├── IJobService.cs
│   ├── IApplicationService.cs
│   ├── IContractService.cs
│   ├── IChatService.cs
│   ├── INotificationService.cs
│   ├── IReviewService.cs
│   ├── IFavoriteService.cs
│   ├── ICategoryService.cs
│   ├── IReportService.cs
│   ├── IDocumentService.cs
│   ├── IDeviceService.cs
│   ├── IBlockedUserService.cs
│   ├── INotificationSettingsService.cs
│   ├── ILocationService.cs
│   └── IJwtService.cs
├── Services/
│   ├── SqlServerConnectionFactory.cs
│   ├── AuthService.cs
│   ├── UserService.cs
│   ├── JobService.cs
│   ├── ApplicationService.cs
│   ├── ContractService.cs
│   ├── ChatService.cs
│   ├── NotificationService.cs
│   ├── ReviewService.cs
│   ├── FavoriteService.cs
│   ├── CategoryService.cs
│   ├── ReportService.cs
│   ├── DocumentService.cs
│   ├── DeviceService.cs
│   ├── BlockedUserService.cs
│   ├── NotificationSettingsService.cs
│   ├── LocationService.cs
│   └── JwtService.cs
├── Program.cs
├── appsettings.json
└── LaboraYa.API.csproj
*/
