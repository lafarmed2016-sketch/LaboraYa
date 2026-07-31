// ============================================================================
// LABORAYA API - IMPLEMENTACIÓN DE SERVICIOS (Llaman a Stored Procedures)
// ============================================================================
// Usa Dapper para llamar a los SPs de SQL Server.
// Copiar cada clase en: Services/
// NuGet necesarios: Dapper, Microsoft.Data.SqlClient
// ============================================================================

using System.Data;
using Microsoft.Data.SqlClient;
using Dapper;
using LaboraYa.API.Interfaces;
using LaboraYa.API.Entities;
using LaboraYa.API.DTOs;

namespace LaboraYa.API.Services
{
    // ─────────────────────────────────────────────────────────────────────────
    // Conexión a SQL Server (se inyecta en todos los services)
    // ─────────────────────────────────────────────────────────────────────────
    public interface IDbConnectionFactory
    {
        IDbConnection CreateConnection();
    }

    public class SqlServerConnectionFactory : IDbConnectionFactory
    {
        private readonly string _connectionString;

        public SqlServerConnectionFactory(string connectionString)
        {
            _connectionString = connectionString;
        }

        public IDbConnection CreateConnection()
        {
            return new SqlConnection(_connectionString);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class AuthService : IAuthService
    {
        private readonly IDbConnectionFactory _db;
        private readonly IJwtService _jwt;

        public AuthService(IDbConnectionFactory db, IJwtService jwt)
        {
            _db = db;
            _jwt = jwt;
        }

        public async Task<AuthResponse> Register(RegisterRequest req, string ip, string ua)
        {
            using var conn = _db.CreateConnection();

            // Hashear password (usar BCrypt.Net-Next NuGet)
            var hash = BCrypt.Net.BCrypt.HashPassword(req.Password);

            var result = await conn.QueryFirstAsync<SpResult>("sp_Auth_Register",
                new { req.Email, req.Phone, PasswordHash = hash, req.FirstName, req.LastName, req.UserType, req.City },
                commandType: CommandType.StoredProcedure);

            if (result.Success == 0)
                throw new AppException(result.Message);

            // Generar tokens
            var accessToken = _jwt.GenerateAccessToken(result.UserId!.Value, req.Email, "USER");
            var refreshToken = _jwt.GenerateRefreshToken();

            // Guardar refresh token
            await conn.ExecuteAsync("sp_Auth_SaveRefreshToken",
                new { UserId = result.UserId, Token = refreshToken, ExpiresAt = DateTime.UtcNow.AddDays(7), IpAddress = ip, UserAgent = ua },
                commandType: CommandType.StoredProcedure);

            return new AuthResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                User = new { id = result.UserId, email = req.Email, firstName = req.FirstName, lastName = req.LastName }
            };
        }

        public async Task<AuthResponse> Login(LoginRequest req, string ip, string ua)
        {
            using var conn = _db.CreateConnection();

            var user = await conn.QueryFirstOrDefaultAsync<UserEntity>("sp_Auth_Login",
                new { req.Email, IpAddress = ip, UserAgent = ua },
                commandType: CommandType.StoredProcedure);

            if (user == null)
                throw new AppException("Credenciales inválidas");

            // Verificar password
            if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash))
            {
                await conn.ExecuteAsync("sp_Auth_LoginFailed", new { req.Email }, commandType: CommandType.StoredProcedure);
                throw new AppException("Credenciales inválidas");
            }

            // Login exitoso
            await conn.ExecuteAsync("sp_Auth_LoginSuccess",
                new { UserId = user.Id, IpAddress = ip, UserAgent = ua },
                commandType: CommandType.StoredProcedure);

            var accessToken = _jwt.GenerateAccessToken(user.Id, user.Email, user.Role);
            var refreshToken = _jwt.GenerateRefreshToken();

            await conn.ExecuteAsync("sp_Auth_SaveRefreshToken",
                new { UserId = user.Id, Token = refreshToken, ExpiresAt = DateTime.UtcNow.AddDays(7), IpAddress = ip, UserAgent = ua },
                commandType: CommandType.StoredProcedure);

            return new AuthResponse
            {
                AccessToken = accessToken,
                RefreshToken = refreshToken,
                User = new { user.Id, user.Email, user.FirstName, user.LastName, user.Avatar, user.Role, user.UserType }
            };
        }

        public async Task<AuthResponse> RefreshToken(string refreshToken)
        {
            using var conn = _db.CreateConnection();

            var token = await conn.QueryFirstOrDefaultAsync<dynamic>("sp_Auth_RefreshToken",
                new { Token = refreshToken },
                commandType: CommandType.StoredProcedure);

            if (token == null || token.Revoked == true || token.ExpiresAt < DateTime.UtcNow)
                throw new AppException("Token inválido o expirado");

            if (token.UserStatus != "ACTIVE")
                throw new AppException("Cuenta no activa");

            // Revocar token viejo y crear uno nuevo
            await conn.ExecuteAsync("sp_Auth_RevokeToken", new { Token = refreshToken }, commandType: CommandType.StoredProcedure);

            var newAccessToken = _jwt.GenerateAccessToken((Guid)token.UserId, (string)token.Email, (string)token.Role);
            var newRefreshToken = _jwt.GenerateRefreshToken();

            await conn.ExecuteAsync("sp_Auth_SaveRefreshToken",
                new { UserId = (Guid)token.UserId, Token = newRefreshToken, ExpiresAt = DateTime.UtcNow.AddDays(7) },
                commandType: CommandType.StoredProcedure);

            return new AuthResponse { AccessToken = newAccessToken, RefreshToken = newRefreshToken };
        }

        public async Task Logout(Guid userId, string refreshToken)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Auth_RevokeToken", new { Token = refreshToken }, commandType: CommandType.StoredProcedure);
        }

        public async Task LogoutAll(Guid userId)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Auth_RevokeAllTokens", new { UserId = userId }, commandType: CommandType.StoredProcedure);
        }

        public Task ForgotPassword(string email)
        {
            // TODO: Enviar email con link de reset
            return Task.CompletedTask;
        }

        public async Task ChangePassword(Guid userId, string currentPasswordHash, string newPasswordHash)
        {
            using var conn = _db.CreateConnection();
            var hash = BCrypt.Net.BCrypt.HashPassword(newPasswordHash);
            await conn.ExecuteAsync("sp_Users_ChangePassword",
                new { UserId = userId, NewPasswordHash = hash },
                commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // USER SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class UserService : IUserService
    {
        private readonly IDbConnectionFactory _db;
        public UserService(IDbConnectionFactory db) => _db = db;

        public async Task<UserEntity?> GetProfile(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<UserEntity>("sp_Users_GetProfile",
                new { UserId = userId }, commandType: CommandType.StoredProcedure);
        }

        public async Task<UserEntity?> GetPublicProfile(Guid userId)
        {
            return await GetProfile(userId); // Mismo SP, el controller filtra campos sensibles
        }

        public async Task<SpResult> UpdateProfile(Guid userId, UpdateProfileRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Users_UpdateProfile",
                new { UserId = userId, req.FirstName, req.LastName, req.Phone, req.City, req.Bio, req.Avatar },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> UpdateWorkerProfile(Guid userId, UpdateWorkerProfileRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Users_UpdateWorkerProfile",
                new { UserId = userId, req.Description, req.YearsExperience, req.Available, req.RadiusKm, req.HourlyRate, req.Latitude, req.Longitude },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> DeleteAccount(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Users_DeleteAccount",
                new { UserId = userId }, commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // JOB SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class JobService : IJobService
    {
        private readonly IDbConnectionFactory _db;
        public JobService(IDbConnectionFactory db) => _db = db;

        public async Task<(List<JobEntity> Jobs, int Total, int TotalPages)> GetFeed(JobQueryParams q, Guid? userId)
        {
            using var conn = _db.CreateConnection();
            var jobs = (await conn.QueryAsync<JobEntity>("sp_Jobs_GetFeed",
                new { q.Page, q.PageSize, q.CategoryId, q.Modality, q.Search, q.IsUrgent, q.Latitude, q.Longitude, q.RadiusKm, UserId = userId },
                commandType: CommandType.StoredProcedure)).ToList();

            var total = jobs.FirstOrDefault()?.TotalCount ?? 0;
            var totalPages = jobs.FirstOrDefault()?.TotalPages ?? 0;
            return (jobs, total, totalPages);
        }

        public async Task<(JobEntity? Job, List<JobImageEntity> Images)> GetById(Guid jobId, Guid? userId)
        {
            using var conn = _db.CreateConnection();
            using var multi = await conn.QueryMultipleAsync("sp_Jobs_GetById",
                new { JobId = jobId, UserId = userId }, commandType: CommandType.StoredProcedure);

            var job = await multi.ReadFirstOrDefaultAsync<JobEntity>();
            var images = (await multi.ReadAsync<JobImageEntity>()).ToList();
            return (job, images);
        }

        public async Task<List<JobEntity>> GetMine(Guid userId, string? status, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<JobEntity>("sp_Jobs_GetMine",
                new { UserId = userId, Status = status, Page = page, PageSize = pageSize },
                commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<List<JobEntity>> GetNearby(double lat, double lng, double radiusKm, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<JobEntity>("sp_Jobs_GetNearby",
                new { Latitude = lat, Longitude = lng, RadiusKm = radiusKm, Page = page, PageSize = pageSize },
                commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> Create(Guid publisherId, CreateJobRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Jobs_Create",
                new {
                    PublisherId = publisherId, req.CategoryId, req.SubcategoryId, req.Title, req.Description,
                    req.Address, req.Reference, req.Latitude, req.Longitude, req.RequiredDate, req.RequiredTime,
                    req.Duration, req.WorkersNeeded, req.ExperienceReq, req.Materials, req.Modality,
                    req.BudgetMin, req.BudgetMax, req.BudgetFixed, req.IsUrgent, req.IsRemote, req.PublishNow
                }, commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> Update(Guid jobId, Guid userId, UpdateJobRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Jobs_Update",
                new { JobId = jobId, UserId = userId, req.Title, req.Description, req.Address, req.BudgetMin, req.BudgetMax, req.IsUrgent, req.Status },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> Delete(Guid jobId, Guid userId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Jobs_Delete",
                new { JobId = jobId, UserId = userId }, commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // APPLICATION SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class ApplicationService : IApplicationService
    {
        private readonly IDbConnectionFactory _db;
        public ApplicationService(IDbConnectionFactory db) => _db = db;

        public async Task<SpResult> Apply(Guid applicantId, ApplyRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Applications_Create",
                new { req.JobId, ApplicantId = applicantId, req.Message, req.ProposedBudget, req.EstimatedTime, req.Availability },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<List<ApplicationEntity>> GetByJob(Guid jobId, Guid userId)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<ApplicationEntity>("sp_Applications_GetByJob",
                new { JobId = jobId, UserId = userId }, commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<List<ApplicationEntity>> GetMine(Guid userId, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<ApplicationEntity>("sp_Applications_GetMine",
                new { UserId = userId, Page = page, PageSize = pageSize }, commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> Accept(Guid applicationId, Guid userId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Applications_Accept",
                new { ApplicationId = applicationId, UserId = userId }, commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> Reject(Guid applicationId, Guid userId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Applications_Reject",
                new { ApplicationId = applicationId, UserId = userId }, commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> Withdraw(Guid applicationId, Guid userId)
        {
            using var conn = _db.CreateConnection();
            // Retirar = el mismo aplicante cancela
            await conn.ExecuteAsync(
                "UPDATE Applications SET Status = 'WITHDRAWN', UpdatedAt = GETUTCDATE() WHERE Id = @Id AND ApplicantId = @UserId",
                new { Id = applicationId, UserId = userId });
            return new SpResult { Success = 1, Message = "Postulación retirada" };
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONTRACT SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class ContractService : IContractService
    {
        private readonly IDbConnectionFactory _db;
        public ContractService(IDbConnectionFactory db) => _db = db;

        public async Task<List<ContractEntity>> GetMine(Guid userId, string? status, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<ContractEntity>("sp_Contracts_GetMine",
                new { UserId = userId, Status = status, Page = page, PageSize = pageSize },
                commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> UpdateStatus(Guid contractId, Guid userId, UpdateContractStatusRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Contracts_UpdateStatus",
                new { ContractId = contractId, UserId = userId, NewStatus = req.Status, Note = req.Note },
                commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHAT SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class ChatService : IChatService
    {
        private readonly IDbConnectionFactory _db;
        public ChatService(IDbConnectionFactory db) => _db = db;

        public async Task<List<ConversationEntity>> GetConversations(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<ConversationEntity>("sp_Chat_GetConversations",
                new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> GetOrCreateConversation(Guid userId, Guid otherUserId, Guid? jobId)
        {
            using var conn = _db.CreateConnection();
            var result = await conn.QueryFirstAsync<SpResult>("sp_Chat_GetOrCreateConversation",
                new { UserId1 = userId, UserId2 = otherUserId, JobId = jobId },
                commandType: CommandType.StoredProcedure);
            return result;
        }

        public async Task<List<MessageEntity>> GetMessages(Guid conversationId, Guid userId, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<MessageEntity>("sp_Chat_GetMessages",
                new { ConversationId = conversationId, UserId = userId, Page = page, PageSize = pageSize },
                commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> SendMessage(Guid conversationId, Guid senderId, SendMessageRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Chat_SendMessage",
                new { ConversationId = conversationId, SenderId = senderId, Content = req.Content, Type = req.Type, Metadata = req.Metadata, ReplyToId = req.ReplyToId },
                commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATION SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class NotificationService : INotificationService
    {
        private readonly IDbConnectionFactory _db;
        public NotificationService(IDbConnectionFactory db) => _db = db;

        public async Task<List<NotificationEntity>> Get(Guid userId, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<NotificationEntity>("sp_Notifications_Get",
                new { UserId = userId, Page = page, PageSize = pageSize },
                commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<int> GetUnreadCount(Guid userId)
        {
            using var conn = _db.CreateConnection();
            var result = await conn.QueryFirstAsync<dynamic>("sp_Notifications_UnreadCount",
                new { UserId = userId }, commandType: CommandType.StoredProcedure);
            return (int)result.UnreadCount;
        }

        public async Task MarkRead(Guid notificationId, Guid userId)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Notifications_MarkRead",
                new { NotificationId = notificationId, UserId = userId }, commandType: CommandType.StoredProcedure);
        }

        public async Task MarkAllRead(Guid userId)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Notifications_MarkAllRead",
                new { UserId = userId }, commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REVIEW SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class ReviewService : IReviewService
    {
        private readonly IDbConnectionFactory _db;
        public ReviewService(IDbConnectionFactory db) => _db = db;

        public async Task<SpResult> Create(Guid reviewerId, CreateReviewRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Reviews_Create",
                new { req.ContractId, ReviewerId = reviewerId, req.Rating, req.Comment, req.Quality, req.Punctuality, req.Communication, req.Professionalism, req.Compliance },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<List<ReviewEntity>> GetByUser(Guid userId, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<ReviewEntity>("sp_Reviews_GetByUser",
                new { UserId = userId, Page = page, PageSize = pageSize },
                commandType: CommandType.StoredProcedure)).ToList();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FAVORITE SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class FavoriteService : IFavoriteService
    {
        private readonly IDbConnectionFactory _db;
        public FavoriteService(IDbConnectionFactory db) => _db = db;

        public async Task<List<FavoriteEntity>> GetMine(Guid userId, int page, int pageSize)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<FavoriteEntity>("sp_Favorites_GetMine",
                new { UserId = userId, Page = page, PageSize = pageSize },
                commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> Add(Guid userId, AddFavoriteRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Favorites_Add",
                new { UserId = userId, req.JobId, req.Type },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> Remove(Guid userId, Guid jobId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Favorites_Remove",
                new { UserId = userId, JobId = jobId },
                commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CATEGORY SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class CategoryService : ICategoryService
    {
        private readonly IDbConnectionFactory _db;
        public CategoryService(IDbConnectionFactory db) => _db = db;

        public async Task<List<CategoryEntity>> GetAll()
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<CategoryEntity>("sp_Categories_GetAll",
                commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<List<CategoryEntity>> GetSubcategories(Guid categoryId)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<CategoryEntity>("sp_Categories_GetSubcategories",
                new { CategoryId = categoryId }, commandType: CommandType.StoredProcedure)).ToList();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REPORT SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class ReportService : IReportService
    {
        private readonly IDbConnectionFactory _db;
        public ReportService(IDbConnectionFactory db) => _db = db;

        public async Task<SpResult> Create(Guid reporterId, CreateReportRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Reports_Create",
                new { ReporterId = reporterId, req.ReportedUserId, req.JobId, req.Reason, req.Description },
                commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DOCUMENT SERVICE (Verificación)
    // ═══════════════════════════════════════════════════════════════════════════
    public class DocumentService : IDocumentService
    {
        private readonly IDbConnectionFactory _db;
        public DocumentService(IDbConnectionFactory db) => _db = db;

        public async Task<List<DocumentEntity>> GetStatus(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<DocumentEntity>("sp_Documents_GetStatus",
                new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> Upload(Guid userId, UploadDocumentRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Documents_Upload",
                new { UserId = userId, req.Type, req.Url }, commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DEVICE SERVICE (Push Notifications)
    // ═══════════════════════════════════════════════════════════════════════════
    public class DeviceService : IDeviceService
    {
        private readonly IDbConnectionFactory _db;
        public DeviceService(IDbConnectionFactory db) => _db = db;

        public async Task Register(Guid userId, RegisterDeviceRequest req)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Devices_Register",
                new { UserId = userId, req.FcmToken, req.Platform, req.DeviceName },
                commandType: CommandType.StoredProcedure);
        }

        public async Task<List<DeviceTokenEntity>> GetTokens(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<DeviceTokenEntity>("sp_Devices_GetTokens",
                new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task Deactivate(Guid userId, string fcmToken)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("sp_Devices_Deactivate",
                new { UserId = userId, FcmToken = fcmToken }, commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // BLOCKED USER SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class BlockedUserService : IBlockedUserService
    {
        private readonly IDbConnectionFactory _db;
        public BlockedUserService(IDbConnectionFactory db) => _db = db;

        public async Task<SpResult> Block(Guid userId, BlockUserRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_BlockedUsers_Block",
                new { UserId = userId, req.BlockedUserId, req.Reason }, commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> Unblock(Guid userId, Guid blockedUserId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_BlockedUsers_Unblock",
                new { UserId = userId, BlockedUserId = blockedUserId }, commandType: CommandType.StoredProcedure);
        }

        public async Task<List<BlockedUserEntity>> GetList(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<BlockedUserEntity>("sp_BlockedUsers_GetList",
                new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATION SETTINGS SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class NotificationSettingsService : INotificationSettingsService
    {
        private readonly IDbConnectionFactory _db;
        public NotificationSettingsService(IDbConnectionFactory db) => _db = db;

        public async Task<NotificationSettingsEntity?> Get(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstOrDefaultAsync<NotificationSettingsEntity>("sp_NotifSettings_Get",
                new { UserId = userId }, commandType: CommandType.StoredProcedure);
        }

        public async Task<SpResult> Update(Guid userId, UpdateNotifSettingsRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_NotifSettings_Update",
                new { UserId = userId, req.PushEnabled, req.EmailEnabled, req.NewApplications, req.ApplicationUpdates, req.NewMessages, req.JobReminders, req.Reviews, req.Promotions },
                commandType: CommandType.StoredProcedure);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // LOCATION SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class LocationService : ILocationService
    {
        private readonly IDbConnectionFactory _db;
        public LocationService(IDbConnectionFactory db) => _db = db;

        public async Task<List<SavedLocationEntity>> GetMine(Guid userId)
        {
            using var conn = _db.CreateConnection();
            return (await conn.QueryAsync<SavedLocationEntity>("sp_Locations_GetMine",
                new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList();
        }

        public async Task<SpResult> Save(Guid userId, SaveLocationRequest req)
        {
            using var conn = _db.CreateConnection();
            return await conn.QueryFirstAsync<SpResult>("sp_Locations_Save",
                new { UserId = userId, req.Label, req.Address, req.Latitude, req.Longitude, req.IsDefault },
                commandType: CommandType.StoredProcedure);
        }

        public async Task Delete(Guid userId, Guid locationId)
        {
            using var conn = _db.CreateConnection();
            await conn.ExecuteAsync("DELETE FROM SavedLocations WHERE Id = @Id AND UserId = @UserId",
                new { Id = locationId, UserId = userId });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // JWT SERVICE
    // ═══════════════════════════════════════════════════════════════════════════
    public class JwtService : IJwtService
    {
        private readonly IConfiguration _config;
        public JwtService(IConfiguration config) => _config = config;

        public string GenerateAccessToken(Guid userId, string email, string role)
        {
            var key = new Microsoft.IdentityModel.Tokens.SymmetricSecurityKey(
                System.Text.Encoding.UTF8.GetBytes(_config["Jwt:Secret"]!));
            var creds = new Microsoft.IdentityModel.Tokens.SigningCredentials(key, Microsoft.IdentityModel.Tokens.SecurityAlgorithms.HmacSha256);

            var claims = new[]
            {
                new System.Security.Claims.Claim("sub", userId.ToString()),
                new System.Security.Claims.Claim("email", email),
                new System.Security.Claims.Claim("role", role),
                new System.Security.Claims.Claim("jti", Guid.NewGuid().ToString())
            };

            var token = new System.IdentityModel.Tokens.Jwt.JwtSecurityToken(
                claims: claims,
                expires: DateTime.UtcNow.AddMinutes(int.Parse(_config["Jwt:ExpiresInMinutes"] ?? "15")),
                signingCredentials: creds);

            return new System.IdentityModel.Tokens.Jwt.JwtSecurityTokenHandler().WriteToken(token);
        }

        public string GenerateRefreshToken()
        {
            var bytes = new byte[64];
            using var rng = System.Security.Cryptography.RandomNumberGenerator.Create();
            rng.GetBytes(bytes);
            return Convert.ToBase64String(bytes);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // EXCEPCIÓN PERSONALIZADA
    // ═══════════════════════════════════════════════════════════════════════════
    public class AppException : Exception
    {
        public AppException(string message) : base(message) { }
    }
}
