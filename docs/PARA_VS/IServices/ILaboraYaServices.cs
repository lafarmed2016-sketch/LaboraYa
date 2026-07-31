using BaseLafarmed2026.Common;
using BaseLafarmed2026.Models;

namespace BaseLafarmed2026.IServices
{
    public interface ILY_AuthService
    {
        Task<LY_AuthResponse> Register(LY_RegisterRequest req, string ip, string ua);
        Task<LY_AuthResponse> Login(LY_LoginRequest req, string ip, string ua);
        Task<LY_AuthResponse> RefreshToken(string token);
        Task Logout(Guid userId, string token);
        Task ChangePassword(Guid userId, string newPassword);
    }

    public interface ILY_UserService
    {
        Task<UserEntity?> GetProfile(Guid userId);
        Task<SpResult> UpdateProfile(Guid userId, LY_UpdateProfileRequest req);
        Task<SpResult> UpdateWorkerProfile(Guid userId, LY_UpdateWorkerProfileRequest req);
        Task<SpResult> DeleteAccount(Guid userId);
    }

    public interface ILY_JobService
    {
        Task<(List<JobEntity> Jobs, int Total, int TotalPages)> GetFeed(LY_JobQueryParams q, Guid? userId);
        Task<(JobEntity? Job, List<JobImageEntity> Images)> GetById(Guid jobId, Guid? userId);
        Task<List<JobEntity>> GetMine(Guid userId, string? status, int page);
        Task<List<JobEntity>> GetNearby(double lat, double lng, double radius, int page);
        Task<SpResult> Create(Guid publisherId, LY_CreateJobRequest req);
        Task<SpResult> Update(Guid jobId, Guid userId, LY_UpdateJobRequest req);
        Task<SpResult> Delete(Guid jobId, Guid userId);
    }

    public interface ILY_ApplicationService
    {
        Task<SpResult> Apply(Guid applicantId, LY_ApplyRequest req);
        Task<List<ApplicationEntity>> GetByJob(Guid jobId, Guid userId);
        Task<List<ApplicationEntity>> GetMine(Guid userId, int page);
        Task<SpResult> Accept(Guid applicationId, Guid userId);
        Task<SpResult> Reject(Guid applicationId, Guid userId);
    }

    public interface ILY_ContractService
    {
        Task<List<ContractEntity>> GetMine(Guid userId, string? status, int page);
        Task<SpResult> UpdateStatus(Guid contractId, Guid userId, LY_UpdateContractStatusRequest req);
    }

    public interface ILY_ChatService
    {
        Task<List<ConversationEntity>> GetConversations(Guid userId);
        Task<SpResult> GetOrCreate(Guid userId, Guid otherUserId, Guid? jobId);
        Task<List<MessageEntity>> GetMessages(Guid convId, Guid userId, int page);
        Task<SpResult> SendMessage(Guid convId, Guid senderId, LY_SendMessageRequest req);
    }

    public interface ILY_NotificationService
    {
        Task<List<NotificationEntity>> Get(Guid userId, int page);
        Task<int> GetUnreadCount(Guid userId);
        Task MarkRead(Guid id, Guid userId);
        Task MarkAllRead(Guid userId);
    }

    public interface ILY_ReviewService
    {
        Task<SpResult> Create(Guid reviewerId, LY_CreateReviewRequest req);
        Task<List<ReviewEntity>> GetByUser(Guid userId, int page);
    }

    public interface ILY_FavoriteService
    {
        Task<List<FavoriteEntity>> GetMine(Guid userId, int page);
        Task<SpResult> Add(Guid userId, LY_AddFavoriteRequest req);
        Task<SpResult> Remove(Guid userId, Guid jobId);
    }

    public interface ILY_CategoryService { Task<List<CategoryEntity>> GetAll(); }
    public interface ILY_ReportService { Task<SpResult> Create(Guid reporterId, LY_CreateReportRequest req); }
    public interface ILY_DocumentService { Task<List<DocumentEntity>> GetStatus(Guid userId); Task<SpResult> Upload(Guid userId, LY_UploadDocumentRequest req); }
    public interface ILY_DeviceService { Task Register(Guid userId, LY_RegisterDeviceRequest req); Task Deactivate(Guid userId, string fcmToken); }
    public interface ILY_BlockedUserService { Task<SpResult> Block(Guid userId, LY_BlockUserRequest req); Task<SpResult> Unblock(Guid userId, Guid blockedUserId); Task<List<BlockedUserEntity>> GetList(Guid userId); }
    public interface ILY_NotifSettingsService { Task<NotificationSettingsEntity?> Get(Guid userId); Task<SpResult> Update(Guid userId, LY_UpdateNotifSettingsRequest req); }

    public interface ILY_JwtService
    {
        string GenerateAccessToken(Guid userId, string email, string role);
        string GenerateRefreshToken();
    }
}
