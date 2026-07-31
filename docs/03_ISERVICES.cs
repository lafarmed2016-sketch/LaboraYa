// ============================================================================
// LABORAYA API - INTERFACES DE SERVICIOS
// ============================================================================
// Copiar cada interface en: Interfaces/
// Estos definen el contrato de cada servicio que llama a los SPs.
// ============================================================================

using LaboraYa.API.DTOs;
using LaboraYa.API.Entities;

namespace LaboraYa.API.Interfaces
{
    public interface IAuthService
    {
        Task<AuthResponse> Register(RegisterRequest request, string ipAddress, string userAgent);
        Task<AuthResponse> Login(LoginRequest request, string ipAddress, string userAgent);
        Task<AuthResponse> RefreshToken(string refreshToken);
        Task Logout(Guid userId, string refreshToken);
        Task LogoutAll(Guid userId);
        Task ForgotPassword(string email);
        Task ChangePassword(Guid userId, string currentPasswordHash, string newPasswordHash);
    }

    public interface IUserService
    {
        Task<UserEntity?> GetProfile(Guid userId);
        Task<UserEntity?> GetPublicProfile(Guid userId);
        Task<SpResult> UpdateProfile(Guid userId, UpdateProfileRequest request);
        Task<SpResult> UpdateWorkerProfile(Guid userId, UpdateWorkerProfileRequest request);
        Task<SpResult> DeleteAccount(Guid userId);
    }

    public interface IJobService
    {
        Task<(List<JobEntity> Jobs, int Total, int TotalPages)> GetFeed(JobQueryParams query, Guid? userId);
        Task<(JobEntity? Job, List<JobImageEntity> Images)> GetById(Guid jobId, Guid? userId);
        Task<List<JobEntity>> GetMine(Guid userId, string? status, int page, int pageSize);
        Task<List<JobEntity>> GetNearby(double lat, double lng, double radiusKm, int page, int pageSize);
        Task<SpResult> Create(Guid publisherId, CreateJobRequest request);
        Task<SpResult> Update(Guid jobId, Guid userId, UpdateJobRequest request);
        Task<SpResult> Delete(Guid jobId, Guid userId);
    }

    public interface IApplicationService
    {
        Task<SpResult> Apply(Guid applicantId, ApplyRequest request);
        Task<List<ApplicationEntity>> GetByJob(Guid jobId, Guid userId);
        Task<List<ApplicationEntity>> GetMine(Guid userId, int page, int pageSize);
        Task<SpResult> Accept(Guid applicationId, Guid userId);
        Task<SpResult> Reject(Guid applicationId, Guid userId);
        Task<SpResult> Withdraw(Guid applicationId, Guid userId);
    }

    public interface IContractService
    {
        Task<List<ContractEntity>> GetMine(Guid userId, string? status, int page, int pageSize);
        Task<SpResult> UpdateStatus(Guid contractId, Guid userId, UpdateContractStatusRequest request);
    }

    public interface IChatService
    {
        Task<List<ConversationEntity>> GetConversations(Guid userId);
        Task<SpResult> GetOrCreateConversation(Guid userId, Guid otherUserId, Guid? jobId);
        Task<List<MessageEntity>> GetMessages(Guid conversationId, Guid userId, int page, int pageSize);
        Task<SpResult> SendMessage(Guid conversationId, Guid senderId, SendMessageRequest request);
    }

    public interface INotificationService
    {
        Task<List<NotificationEntity>> Get(Guid userId, int page, int pageSize);
        Task<int> GetUnreadCount(Guid userId);
        Task MarkRead(Guid notificationId, Guid userId);
        Task MarkAllRead(Guid userId);
    }

    public interface IReviewService
    {
        Task<SpResult> Create(Guid reviewerId, CreateReviewRequest request);
        Task<List<ReviewEntity>> GetByUser(Guid userId, int page, int pageSize);
    }

    public interface IFavoriteService
    {
        Task<List<FavoriteEntity>> GetMine(Guid userId, int page, int pageSize);
        Task<SpResult> Add(Guid userId, AddFavoriteRequest request);
        Task<SpResult> Remove(Guid userId, Guid jobId);
    }

    public interface ICategoryService
    {
        Task<List<CategoryEntity>> GetAll();
        Task<List<CategoryEntity>> GetSubcategories(Guid categoryId);
    }

    public interface IReportService
    {
        Task<SpResult> Create(Guid reporterId, CreateReportRequest request);
    }

    public interface IDocumentService
    {
        Task<List<DocumentEntity>> GetStatus(Guid userId);
        Task<SpResult> Upload(Guid userId, UploadDocumentRequest request);
    }

    public interface IDeviceService
    {
        Task Register(Guid userId, RegisterDeviceRequest request);
        Task<List<DeviceTokenEntity>> GetTokens(Guid userId);
        Task Deactivate(Guid userId, string fcmToken);
    }

    public interface IBlockedUserService
    {
        Task<SpResult> Block(Guid userId, BlockUserRequest request);
        Task<SpResult> Unblock(Guid userId, Guid blockedUserId);
        Task<List<BlockedUserEntity>> GetList(Guid userId);
    }

    public interface INotificationSettingsService
    {
        Task<NotificationSettingsEntity?> Get(Guid userId);
        Task<SpResult> Update(Guid userId, UpdateNotifSettingsRequest request);
    }

    public interface ILocationService
    {
        Task<List<SavedLocationEntity>> GetMine(Guid userId);
        Task<SpResult> Save(Guid userId, SaveLocationRequest request);
        Task Delete(Guid userId, Guid locationId);
    }

    public interface IJwtService
    {
        string GenerateAccessToken(Guid userId, string email, string role);
        string GenerateRefreshToken();
    }
}
