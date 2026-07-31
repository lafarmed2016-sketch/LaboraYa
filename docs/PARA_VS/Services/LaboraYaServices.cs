using System.Data;
using Dapper;
using BaseLafarmed2026.Common;
using BaseLafarmed2026.Infrastructure;
using BaseLafarmed2026.IServices;
using BaseLafarmed2026.Models;
using BaseLafarmed2026.Utils;

namespace BaseLafarmed2026.Services
{
    // ══════════ AUTH ══════════
    public class LY_AuthService : ILY_AuthService
    {
        private readonly ILaboraYaDb _db;
        private readonly ILY_JwtService _jwt;
        public LY_AuthService(ILaboraYaDb db, ILY_JwtService jwt) { _db = db; _jwt = jwt; }

        public async Task<LY_AuthResponse> Register(LY_RegisterRequest req, string ip, string ua)
        {
            using var c = _db.CreateConnection();
            var hash = BCrypt.Net.BCrypt.HashPassword(req.Password);
            var r = await c.QueryFirstAsync<SpResult>("sp_Auth_Register", new { req.Email, req.Phone, PasswordHash = hash, req.FirstName, req.LastName, req.UserType, req.City }, commandType: CommandType.StoredProcedure);
            if (r.Success == 0) throw new LaboraYaException(r.Message);
            var at = _jwt.GenerateAccessToken(r.UserId!.Value, req.Email, "USER");
            var rt = _jwt.GenerateRefreshToken();
            await c.ExecuteAsync("sp_Auth_SaveRefreshToken", new { UserId = r.UserId, Token = rt, ExpiresAt = DateTime.UtcNow.AddDays(7), IpAddress = ip, UserAgent = ua }, commandType: CommandType.StoredProcedure);
            return new LY_AuthResponse { AccessToken = at, RefreshToken = rt, User = new { id = r.UserId, email = req.Email, firstName = req.FirstName, lastName = req.LastName } };
        }

        public async Task<LY_AuthResponse> Login(LY_LoginRequest req, string ip, string ua)
        {
            using var c = _db.CreateConnection();
            var user = await c.QueryFirstOrDefaultAsync<UserEntity>("sp_Auth_Login", new { req.Email, IpAddress = ip, UserAgent = ua }, commandType: CommandType.StoredProcedure);
            if (user == null) throw new LaboraYaException("Credenciales inválidas");
            if (!BCrypt.Net.BCrypt.Verify(req.Password, user.PasswordHash)) { await c.ExecuteAsync("sp_Auth_LoginFailed", new { req.Email }, commandType: CommandType.StoredProcedure); throw new LaboraYaException("Credenciales inválidas"); }
            await c.ExecuteAsync("sp_Auth_LoginSuccess", new { UserId = user.Id, IpAddress = ip, UserAgent = ua }, commandType: CommandType.StoredProcedure);
            var at = _jwt.GenerateAccessToken(user.Id, user.Email, user.Role);
            var rt = _jwt.GenerateRefreshToken();
            await c.ExecuteAsync("sp_Auth_SaveRefreshToken", new { UserId = user.Id, Token = rt, ExpiresAt = DateTime.UtcNow.AddDays(7), IpAddress = ip, UserAgent = ua }, commandType: CommandType.StoredProcedure);
            return new LY_AuthResponse { AccessToken = at, RefreshToken = rt, User = new { user.Id, user.Email, user.FirstName, user.LastName, user.Avatar, user.Role, user.UserType } };
        }

        public async Task<LY_AuthResponse> RefreshToken(string token)
        {
            using var c = _db.CreateConnection();
            var t = await c.QueryFirstOrDefaultAsync<dynamic>("sp_Auth_RefreshToken", new { Token = token }, commandType: CommandType.StoredProcedure);
            if (t == null || (bool)t.Revoked || (DateTime)t.ExpiresAt < DateTime.UtcNow) throw new LaboraYaException("Token inválido");
            await c.ExecuteAsync("sp_Auth_RevokeToken", new { Token = token }, commandType: CommandType.StoredProcedure);
            var at = _jwt.GenerateAccessToken((Guid)t.UserId, (string)t.Email, (string)t.Role);
            var rt = _jwt.GenerateRefreshToken();
            await c.ExecuteAsync("sp_Auth_SaveRefreshToken", new { UserId = (Guid)t.UserId, Token = rt, ExpiresAt = DateTime.UtcNow.AddDays(7) }, commandType: CommandType.StoredProcedure);
            return new LY_AuthResponse { AccessToken = at, RefreshToken = rt };
        }

        public async Task Logout(Guid userId, string token) { using var c = _db.CreateConnection(); await c.ExecuteAsync("sp_Auth_RevokeToken", new { Token = token }, commandType: CommandType.StoredProcedure); }
        public async Task ChangePassword(Guid userId, string newPwd) { using var c = _db.CreateConnection(); await c.ExecuteAsync("sp_Users_ChangePassword", new { UserId = userId, NewPasswordHash = BCrypt.Net.BCrypt.HashPassword(newPwd) }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ USER ══════════
    public class LY_UserService : ILY_UserService
    {
        private readonly ILaboraYaDb _db;
        public LY_UserService(ILaboraYaDb db) => _db = db;
        public async Task<UserEntity?> GetProfile(Guid userId) { using var c = _db.CreateConnection(); return await c.QueryFirstOrDefaultAsync<UserEntity>("sp_Users_GetProfile", new { UserId = userId }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> UpdateProfile(Guid userId, LY_UpdateProfileRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Users_UpdateProfile", new { UserId = userId, req.FirstName, req.LastName, req.Phone, req.City, req.Bio, req.Avatar }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> UpdateWorkerProfile(Guid userId, LY_UpdateWorkerProfileRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Users_UpdateWorkerProfile", new { UserId = userId, req.Description, req.YearsExperience, req.Available, req.RadiusKm, req.HourlyRate, req.Latitude, req.Longitude }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> DeleteAccount(Guid userId) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Users_DeleteAccount", new { UserId = userId }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ JOB ══════════
    public class LY_JobService : ILY_JobService
    {
        private readonly ILaboraYaDb _db;
        public LY_JobService(ILaboraYaDb db) => _db = db;
        public async Task<(List<JobEntity>, int, int)> GetFeed(LY_JobQueryParams q, Guid? userId) { using var c = _db.CreateConnection(); var jobs = (await c.QueryAsync<JobEntity>("sp_Jobs_GetFeed", new { q.Page, q.PageSize, q.CategoryId, q.Modality, q.Search, q.IsUrgent, q.Latitude, q.Longitude, q.RadiusKm, UserId = userId }, commandType: CommandType.StoredProcedure)).ToList(); return (jobs, jobs.FirstOrDefault()?.TotalCount ?? 0, jobs.FirstOrDefault()?.TotalPages ?? 0); }
        public async Task<(JobEntity?, List<JobImageEntity>)> GetById(Guid jobId, Guid? userId) { using var c = _db.CreateConnection(); using var m = await c.QueryMultipleAsync("sp_Jobs_GetById", new { JobId = jobId, UserId = userId }, commandType: CommandType.StoredProcedure); return (await m.ReadFirstOrDefaultAsync<JobEntity>(), (await m.ReadAsync<JobImageEntity>()).ToList()); }
        public async Task<List<JobEntity>> GetMine(Guid userId, string? status, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<JobEntity>("sp_Jobs_GetMine", new { UserId = userId, Status = status, Page = page, PageSize = 20 }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<List<JobEntity>> GetNearby(double lat, double lng, double radius, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<JobEntity>("sp_Jobs_GetNearby", new { Latitude = lat, Longitude = lng, RadiusKm = radius, Page = page, PageSize = 20 }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<SpResult> Create(Guid pub, LY_CreateJobRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Jobs_Create", new { PublisherId = pub, req.CategoryId, SubcategoryId = (Guid?)null, req.Title, req.Description, req.Address, Reference = (string?)null, req.Latitude, req.Longitude, RequiredDate = (string?)null, RequiredTime = (string?)null, req.Duration, req.WorkersNeeded, ExperienceReq = (string?)null, req.Materials, req.Modality, req.BudgetMin, req.BudgetMax, req.BudgetFixed, req.IsUrgent, req.IsRemote, req.PublishNow }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> Update(Guid jobId, Guid userId, LY_UpdateJobRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Jobs_Update", new { JobId = jobId, UserId = userId, req.Title, req.Description, req.Address, req.BudgetMin, req.BudgetMax, req.IsUrgent, req.Status }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> Delete(Guid jobId, Guid userId) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Jobs_Delete", new { JobId = jobId, UserId = userId }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ APPLICATION ══════════
    public class LY_ApplicationService : ILY_ApplicationService
    {
        private readonly ILaboraYaDb _db;
        public LY_ApplicationService(ILaboraYaDb db) => _db = db;
        public async Task<SpResult> Apply(Guid applicantId, LY_ApplyRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Applications_Create", new { req.JobId, ApplicantId = applicantId, req.Message, req.ProposedBudget, req.EstimatedTime, Availability = (string?)null }, commandType: CommandType.StoredProcedure); }
        public async Task<List<ApplicationEntity>> GetByJob(Guid jobId, Guid userId) { using var c = _db.CreateConnection(); return (await c.QueryAsync<ApplicationEntity>("sp_Applications_GetByJob", new { JobId = jobId, UserId = userId }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<List<ApplicationEntity>> GetMine(Guid userId, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<ApplicationEntity>("sp_Applications_GetMine", new { UserId = userId, Page = page, PageSize = 20 }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<SpResult> Accept(Guid id, Guid userId) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Applications_Accept", new { ApplicationId = id, UserId = userId }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> Reject(Guid id, Guid userId) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Applications_Reject", new { ApplicationId = id, UserId = userId }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ CONTRACT ══════════
    public class LY_ContractService : ILY_ContractService
    {
        private readonly ILaboraYaDb _db;
        public LY_ContractService(ILaboraYaDb db) => _db = db;
        public async Task<List<ContractEntity>> GetMine(Guid userId, string? status, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<ContractEntity>("sp_Contracts_GetMine", new { UserId = userId, Status = status, Page = page, PageSize = 20 }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<SpResult> UpdateStatus(Guid contractId, Guid userId, LY_UpdateContractStatusRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Contracts_UpdateStatus", new { ContractId = contractId, UserId = userId, NewStatus = req.Status, Note = req.Note }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ CHAT ══════════
    public class LY_ChatService : ILY_ChatService
    {
        private readonly ILaboraYaDb _db;
        public LY_ChatService(ILaboraYaDb db) => _db = db;
        public async Task<List<ConversationEntity>> GetConversations(Guid userId) { using var c = _db.CreateConnection(); return (await c.QueryAsync<ConversationEntity>("sp_Chat_GetConversations", new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<SpResult> GetOrCreate(Guid userId, Guid otherUserId, Guid? jobId) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Chat_GetOrCreateConversation", new { UserId1 = userId, UserId2 = otherUserId, JobId = jobId }, commandType: CommandType.StoredProcedure); }
        public async Task<List<MessageEntity>> GetMessages(Guid convId, Guid userId, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<MessageEntity>("sp_Chat_GetMessages", new { ConversationId = convId, UserId = userId, Page = page, PageSize = 50 }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<SpResult> SendMessage(Guid convId, Guid senderId, LY_SendMessageRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Chat_SendMessage", new { ConversationId = convId, SenderId = senderId, Content = req.Content, Type = req.Type, Metadata = (string?)null, ReplyToId = (Guid?)null }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ NOTIFICATION ══════════
    public class LY_NotificationService : ILY_NotificationService
    {
        private readonly ILaboraYaDb _db;
        public LY_NotificationService(ILaboraYaDb db) => _db = db;
        public async Task<List<NotificationEntity>> Get(Guid userId, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<NotificationEntity>("sp_Notifications_Get", new { UserId = userId, Page = page, PageSize = 30 }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<int> GetUnreadCount(Guid userId) { using var c = _db.CreateConnection(); var r = await c.QueryFirstAsync<dynamic>("sp_Notifications_UnreadCount", new { UserId = userId }, commandType: CommandType.StoredProcedure); return (int)r.UnreadCount; }
        public async Task MarkRead(Guid id, Guid userId) { using var c = _db.CreateConnection(); await c.ExecuteAsync("sp_Notifications_MarkRead", new { NotificationId = id, UserId = userId }, commandType: CommandType.StoredProcedure); }
        public async Task MarkAllRead(Guid userId) { using var c = _db.CreateConnection(); await c.ExecuteAsync("sp_Notifications_MarkAllRead", new { UserId = userId }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ REVIEW ══════════
    public class LY_ReviewService : ILY_ReviewService
    {
        private readonly ILaboraYaDb _db;
        public LY_ReviewService(ILaboraYaDb db) => _db = db;
        public async Task<SpResult> Create(Guid reviewerId, LY_CreateReviewRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Reviews_Create", new { req.ContractId, ReviewerId = reviewerId, req.Rating, req.Comment, Quality = (int?)null, Punctuality = (int?)null, Communication = (int?)null, Professionalism = (int?)null, Compliance = (int?)null }, commandType: CommandType.StoredProcedure); }
        public async Task<List<ReviewEntity>> GetByUser(Guid userId, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<ReviewEntity>("sp_Reviews_GetByUser", new { UserId = userId, Page = page, PageSize = 20 }, commandType: CommandType.StoredProcedure)).ToList(); }
    }

    // ══════════ FAVORITE ══════════
    public class LY_FavoriteService : ILY_FavoriteService
    {
        private readonly ILaboraYaDb _db;
        public LY_FavoriteService(ILaboraYaDb db) => _db = db;
        public async Task<List<FavoriteEntity>> GetMine(Guid userId, int page) { using var c = _db.CreateConnection(); return (await c.QueryAsync<FavoriteEntity>("sp_Favorites_GetMine", new { UserId = userId, Page = page, PageSize = 20 }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<SpResult> Add(Guid userId, LY_AddFavoriteRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Favorites_Add", new { UserId = userId, req.JobId, Type = "JOB" }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> Remove(Guid userId, Guid jobId) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Favorites_Remove", new { UserId = userId, JobId = jobId }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ CATEGORY ══════════
    public class LY_CategoryService : ILY_CategoryService
    {
        private readonly ILaboraYaDb _db;
        public LY_CategoryService(ILaboraYaDb db) => _db = db;
        public async Task<List<CategoryEntity>> GetAll() { using var c = _db.CreateConnection(); return (await c.QueryAsync<CategoryEntity>("sp_Categories_GetAll", commandType: CommandType.StoredProcedure)).ToList(); }
    }

    // ══════════ REPORT ══════════
    public class LY_ReportService : ILY_ReportService
    {
        private readonly ILaboraYaDb _db;
        public LY_ReportService(ILaboraYaDb db) => _db = db;
        public async Task<SpResult> Create(Guid reporterId, LY_CreateReportRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Reports_Create", new { ReporterId = reporterId, req.ReportedUserId, req.JobId, req.Reason, req.Description }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ DOCUMENT ══════════
    public class LY_DocumentService : ILY_DocumentService
    {
        private readonly ILaboraYaDb _db;
        public LY_DocumentService(ILaboraYaDb db) => _db = db;
        public async Task<List<DocumentEntity>> GetStatus(Guid userId) { using var c = _db.CreateConnection(); return (await c.QueryAsync<DocumentEntity>("sp_Documents_GetStatus", new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList(); }
        public async Task<SpResult> Upload(Guid userId, LY_UploadDocumentRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_Documents_Upload", new { UserId = userId, req.Type, req.Url }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ DEVICE ══════════
    public class LY_DeviceService : ILY_DeviceService
    {
        private readonly ILaboraYaDb _db;
        public LY_DeviceService(ILaboraYaDb db) => _db = db;
        public async Task Register(Guid userId, LY_RegisterDeviceRequest req) { using var c = _db.CreateConnection(); await c.ExecuteAsync("sp_Devices_Register", new { UserId = userId, req.FcmToken, req.Platform, DeviceName = (string?)null }, commandType: CommandType.StoredProcedure); }
        public async Task Deactivate(Guid userId, string fcmToken) { using var c = _db.CreateConnection(); await c.ExecuteAsync("sp_Devices_Deactivate", new { UserId = userId, FcmToken = fcmToken }, commandType: CommandType.StoredProcedure); }
    }

    // ══════════ BLOCKED USER ══════════
    public class LY_BlockedUserService : ILY_BlockedUserService
    {
        private readonly ILaboraYaDb _db;
        public LY_BlockedUserService(ILaboraYaDb db) => _db = db;
        public async Task<SpResult> Block(Guid userId, LY_BlockUserRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_BlockedUsers_Block", new { UserId = userId, req.BlockedUserId, Reason = (string?)null }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> Unblock(Guid userId, Guid blockedUserId) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_BlockedUsers_Unblock", new { UserId = userId, BlockedUserId = blockedUserId }, commandType: CommandType.StoredProcedure); }
        public async Task<List<BlockedUserEntity>> GetList(Guid userId) { using var c = _db.CreateConnection(); return (await c.QueryAsync<BlockedUserEntity>("sp_BlockedUsers_GetList", new { UserId = userId }, commandType: CommandType.StoredProcedure)).ToList(); }
    }

    // ══════════ NOTIF SETTINGS ══════════
    public class LY_NotifSettingsService : ILY_NotifSettingsService
    {
        private readonly ILaboraYaDb _db;
        public LY_NotifSettingsService(ILaboraYaDb db) => _db = db;
        public async Task<NotificationSettingsEntity?> Get(Guid userId) { using var c = _db.CreateConnection(); return await c.QueryFirstOrDefaultAsync<NotificationSettingsEntity>("sp_NotifSettings_Get", new { UserId = userId }, commandType: CommandType.StoredProcedure); }
        public async Task<SpResult> Update(Guid userId, LY_UpdateNotifSettingsRequest req) { using var c = _db.CreateConnection(); return await c.QueryFirstAsync<SpResult>("sp_NotifSettings_Update", new { UserId = userId, req.PushEnabled, EmailEnabled = (bool?)null, NewApplications = (bool?)null, ApplicationUpdates = (bool?)null, req.NewMessages, JobReminders = (bool?)null, req.Reviews, Promotions = (bool?)null }, commandType: CommandType.StoredProcedure); }
    }
}
