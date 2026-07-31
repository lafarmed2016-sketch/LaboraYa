// ============================================================================
// LABORAYA API - ENTIDADES Y DTOs
// ============================================================================
// Copiar cada clase en su archivo correspondiente dentro de tu proyecto:
//   - Entities/ (modelos de respuesta del SP)
//   - DTOs/ (objetos de entrada/salida del API)
//   - Enums/ (enumeraciones)
// ============================================================================

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS (Archivo: Enums/LaboraYaEnums.cs)
// ─────────────────────────────────────────────────────────────────────────────

namespace LaboraYa.API.Enums
{
    public enum UserRole { USER, ADMIN, SUPER_ADMIN }
    public enum UserType { WORKER, EMPLOYER, BOTH }
    public enum UserStatus { ACTIVE, INACTIVE, SUSPENDED, BLOCKED, DELETED }
    public enum JobStatus { DRAFT, PUBLISHED, RECEIVING_APPLICATIONS, IN_SELECTION, ASSIGNED, IN_PROGRESS, COMPLETED, CANCELLED, PAUSED, EXPIRED, REPORTED, BLOCKED }
    public enum JobModality { PER_DAY, PER_WEEK, PER_MONTH, PER_CONTRACT, PER_TASK, FULL_TIME, PART_TIME }
    public enum MaterialsProvided { BY_EMPLOYER, BY_WORKER, TO_COORDINATE }
    public enum ApplicationStatus { SENT, VIEWED, PRESELECTED, ACCEPTED, REJECTED, WITHDRAWN, CANCELLED }
    public enum ContractStatus { PENDING, ACCEPTED, CONFIRMED, IN_PROGRESS, PENDING_CONFIRMATION, COMPLETED, CANCELLED, IN_DISPUTE }
    public enum MessageType { TEXT, IMAGE, LOCATION, FILE, SYSTEM }
    public enum MessageStatus { SENT, DELIVERED, READ }
    public enum PaymentMethodType { CASH, TRANSFER, YAPE, PLIN, TO_COORDINATE }
    public enum PaymentStatus { PENDING, CONFIRMED, DISPUTED }
    public enum VerificationStatus { PENDING, APPROVED, REJECTED }
}

// ─────────────────────────────────────────────────────────────────────────────
// ENTIDADES - Mapean las respuestas de los Stored Procedures
// (Archivo: Entities/...)
// ─────────────────────────────────────────────────────────────────────────────

namespace LaboraYa.API.Entities
{
    public class UserEntity
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string? PasswordHash { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? Avatar { get; set; }
        public string Role { get; set; } = "USER";
        public string UserType { get; set; } = "BOTH";
        public string Status { get; set; } = "ACTIVE";
        public bool EmailVerified { get; set; }
        public bool PhoneVerified { get; set; }
        public string? City { get; set; }
        public string? Bio { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public DateTime? LastLoginAt { get; set; }
        public int LoginAttempts { get; set; }
        public DateTime CreatedAt { get; set; }

        // Worker Profile (JOIN)
        public string? WorkerDescription { get; set; }
        public int? YearsExperience { get; set; }
        public bool? Available { get; set; }
        public double? RadiusKm { get; set; }
        public decimal? HourlyRate { get; set; }
        public int? CompletedJobs { get; set; }
        public int? CancelledJobs { get; set; }
        public decimal? WorkerRating { get; set; }
        public int? WorkerReviews { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }

        // Employer Profile (JOIN)
        public string? CompanyName { get; set; }
        public string? CompanyType { get; set; }
        public string? RUC { get; set; }
        public string? EmployerDescription { get; set; }
        public int? CompletedHires { get; set; }
        public decimal? EmployerRating { get; set; }
        public int? EmployerReviews { get; set; }
        public bool? EmployerVerified { get; set; }
    }

    public class JobEntity
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string? Address { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string Modality { get; set; } = string.Empty;
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool BudgetFixed { get; set; }
        public string Currency { get; set; } = "PEN";
        public bool IsUrgent { get; set; }
        public bool IsRemote { get; set; }
        public string Status { get; set; } = "DRAFT";
        public string? Duration { get; set; }
        public int WorkersNeeded { get; set; }
        public string Materials { get; set; } = "TO_COORDINATE";
        public int ApplicantsCount { get; set; }
        public int ViewsCount { get; set; }
        public DateTime? PublishedAt { get; set; }
        public DateTime CreatedAt { get; set; }

        // Category (JOIN)
        public Guid CategoryId { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string? CategoryIcon { get; set; }
        public string? SubcategoryName { get; set; }

        // Publisher (JOIN)
        public Guid PublisherId { get; set; }
        public string PublisherFirstName { get; set; } = string.Empty;
        public string PublisherLastName { get; set; } = string.Empty;
        public string? PublisherAvatar { get; set; }
        public decimal? PublisherRating { get; set; }
        public int? PublisherReviews { get; set; }
        public bool? PublisherVerified { get; set; }

        // Paginación
        public int? TotalCount { get; set; }
        public int? TotalPages { get; set; }
    }

    public class JobImageEntity
    {
        public Guid Id { get; set; }
        public string Url { get; set; } = string.Empty;
        public int SortOrder { get; set; }
    }

    public class ApplicationEntity
    {
        public Guid Id { get; set; }
        public string? Message { get; set; }
        public decimal? ProposedBudget { get; set; }
        public string? EstimatedTime { get; set; }
        public string? Availability { get; set; }
        public string Status { get; set; } = "SENT";
        public DateTime? ViewedAt { get; set; }
        public DateTime? RespondedAt { get; set; }
        public DateTime CreatedAt { get; set; }

        // Applicant info (JOIN)
        public Guid ApplicantId { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Avatar { get; set; }
        public string? City { get; set; }
        public decimal? AverageRating { get; set; }
        public int? TotalReviews { get; set; }
        public int? CompletedJobs { get; set; }
        public int? YearsExperience { get; set; }

        // Job info (para GetMine)
        public Guid? JobId { get; set; }
        public string? Title { get; set; }
        public string? JobStatus { get; set; }
        public string? Modality { get; set; }
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool? IsUrgent { get; set; }
        public string? CategoryName { get; set; }
        public string? EmployerFirstName { get; set; }
        public string? EmployerLastName { get; set; }
        public string? EmployerAvatar { get; set; }
    }

    public class ContractEntity
    {
        public Guid Id { get; set; }
        public string Status { get; set; } = "PENDING";
        public decimal? AgreedBudget { get; set; }
        public string PaymentMethod { get; set; } = "TO_COORDINATE";
        public string PaymentStatus { get; set; } = "PENDING";
        public DateTime? StartedAt { get; set; }
        public DateTime? CompletedAt { get; set; }
        public DateTime CreatedAt { get; set; }
        public Guid JobId { get; set; }
        public string? JobTitle { get; set; }
        public string? Modality { get; set; }
        public string? CategoryName { get; set; }
        public string? OtherFirstName { get; set; }
        public string? OtherLastName { get; set; }
        public string? OtherAvatar { get; set; }
        public string? MyRole { get; set; }
    }

    public class ConversationEntity
    {
        public Guid ConversationId { get; set; }
        public DateTime UpdatedAt { get; set; }
        public Guid ParticipantId { get; set; }
        public string ParticipantFirstName { get; set; } = string.Empty;
        public string ParticipantLastName { get; set; } = string.Empty;
        public string? ParticipantAvatar { get; set; }
        public string? LastMessage { get; set; }
        public string? LastMessageType { get; set; }
        public DateTime? LastMessageAt { get; set; }
        public Guid? LastMessageSenderId { get; set; }
        public int UnreadCount { get; set; }
    }

    public class MessageEntity
    {
        public Guid Id { get; set; }
        public string? Content { get; set; }
        public string Type { get; set; } = "TEXT";
        public string Status { get; set; } = "SENT";
        public string? Metadata { get; set; }
        public Guid SenderId { get; set; }
        public Guid? ReplyToId { get; set; }
        public bool DeletedForAll { get; set; }
        public DateTime CreatedAt { get; set; }
        public string SenderFirstName { get; set; } = string.Empty;
        public string SenderLastName { get; set; } = string.Empty;
        public string? SenderAvatar { get; set; }
    }

    public class ReviewEntity
    {
        public Guid Id { get; set; }
        public decimal Rating { get; set; }
        public string? Comment { get; set; }
        public int? Quality { get; set; }
        public int? Punctuality { get; set; }
        public int? Communication { get; set; }
        public int? Professionalism { get; set; }
        public int? Compliance { get; set; }
        public DateTime CreatedAt { get; set; }
        public string ReviewerFirstName { get; set; } = string.Empty;
        public string ReviewerLastName { get; set; } = string.Empty;
        public string? ReviewerAvatar { get; set; }
        public string? JobTitle { get; set; }
    }

    public class NotificationEntity
    {
        public Guid Id { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string Body { get; set; } = string.Empty;
        public string? Data { get; set; }
        public bool IsRead { get; set; }
        public DateTime? ReadAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class FavoriteEntity
    {
        public Guid FavoriteId { get; set; }
        public DateTime FavoritedAt { get; set; }
        public Guid JobId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Status { get; set; } = string.Empty;
        public string Modality { get; set; } = string.Empty;
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool BudgetFixed { get; set; }
        public bool IsUrgent { get; set; }
        public string? Address { get; set; }
        public DateTime? PublishedAt { get; set; }
        public string CategoryName { get; set; } = string.Empty;
        public string? CategoryIcon { get; set; }
        public string? PublisherFirstName { get; set; }
        public string? PublisherLastName { get; set; }
    }

    public class CategoryEntity
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Icon { get; set; }
        public string? Image { get; set; }
        public int SortOrder { get; set; }
    }

    public class DocumentEntity
    {
        public Guid Id { get; set; }
        public string Type { get; set; } = string.Empty;
        public string Status { get; set; } = "PENDING";
        public string? Note { get; set; }
        public DateTime? ReviewedAt { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class DeviceTokenEntity
    {
        public string FcmToken { get; set; } = string.Empty;
        public string Platform { get; set; } = string.Empty;
    }

    public class BlockedUserEntity
    {
        public Guid BlockedUserId { get; set; }
        public string? Reason { get; set; }
        public DateTime CreatedAt { get; set; }
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string? Avatar { get; set; }
    }

    public class NotificationSettingsEntity
    {
        public bool PushEnabled { get; set; }
        public bool EmailEnabled { get; set; }
        public bool NewApplications { get; set; }
        public bool ApplicationUpdates { get; set; }
        public bool NewMessages { get; set; }
        public bool JobReminders { get; set; }
        public bool Reviews { get; set; }
        public bool Promotions { get; set; }
    }

    public class SavedLocationEntity
    {
        public Guid Id { get; set; }
        public string Label { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public bool IsDefault { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // Resultado genérico de los SPs
    public class SpResult
    {
        public int Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public Guid? UserId { get; set; }
        public Guid? JobId { get; set; }
        public Guid? ApplicationId { get; set; }
        public Guid? ContractId { get; set; }
        public Guid? MessageId { get; set; }
        public Guid? ReviewId { get; set; }
        public Guid? ConversationId { get; set; }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// DTOs - Entrada y Salida del API
// (Archivo: DTOs/...)
// ─────────────────────────────────────────────────────────────────────────────

namespace LaboraYa.API.DTOs
{
    // ── Auth ──
    public class RegisterRequest
    {
        public string FirstName { get; set; } = string.Empty;
        public string LastName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string Password { get; set; } = string.Empty;
        public string UserType { get; set; } = "BOTH";
        public string? City { get; set; }
    }

    public class LoginRequest
    {
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }

    public class RefreshTokenRequest
    {
        public string RefreshToken { get; set; } = string.Empty;
    }

    public class ForgotPasswordRequest
    {
        public string Email { get; set; } = string.Empty;
    }

    public class ChangePasswordRequest
    {
        public string CurrentPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }

    public class AuthResponse
    {
        public string AccessToken { get; set; } = string.Empty;
        public string RefreshToken { get; set; } = string.Empty;
        public object? User { get; set; }
    }

    // ── Users ──
    public class UpdateProfileRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Phone { get; set; }
        public string? City { get; set; }
        public string? Bio { get; set; }
        public string? Avatar { get; set; }
    }

    public class UpdateWorkerProfileRequest
    {
        public string? Description { get; set; }
        public int? YearsExperience { get; set; }
        public bool? Available { get; set; }
        public double? RadiusKm { get; set; }
        public decimal? HourlyRate { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }

    // ── Jobs ──
    public class CreateJobRequest
    {
        public Guid CategoryId { get; set; }
        public Guid? SubcategoryId { get; set; }
        public string Title { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string? Address { get; set; }
        public string? Reference { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string? RequiredDate { get; set; }
        public string? RequiredTime { get; set; }
        public string? Duration { get; set; }
        public int WorkersNeeded { get; set; } = 1;
        public string? ExperienceReq { get; set; }
        public string Materials { get; set; } = "TO_COORDINATE";
        public string Modality { get; set; } = string.Empty;
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool BudgetFixed { get; set; }
        public bool IsUrgent { get; set; }
        public bool IsRemote { get; set; }
        public bool PublishNow { get; set; } = true;
    }

    public class UpdateJobRequest
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? Address { get; set; }
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool? IsUrgent { get; set; }
        public string? Status { get; set; }
    }

    public class JobQueryParams
    {
        public int Page { get; set; } = 1;
        public int PageSize { get; set; } = 20;
        public Guid? CategoryId { get; set; }
        public string? Modality { get; set; }
        public string? Search { get; set; }
        public bool? IsUrgent { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public double? RadiusKm { get; set; }
    }

    // ── Applications ──
    public class ApplyRequest
    {
        public Guid JobId { get; set; }
        public string? Message { get; set; }
        public decimal? ProposedBudget { get; set; }
        public string? EstimatedTime { get; set; }
        public string? Availability { get; set; }
    }

    // ── Contracts ──
    public class UpdateContractStatusRequest
    {
        public string Status { get; set; } = string.Empty;
        public string? Note { get; set; }
    }

    // ── Chat ──
    public class CreateConversationRequest
    {
        public Guid OtherUserId { get; set; }
        public Guid? JobId { get; set; }
    }

    public class SendMessageRequest
    {
        public string Content { get; set; } = string.Empty;
        public string Type { get; set; } = "TEXT";
        public string? Metadata { get; set; }
        public Guid? ReplyToId { get; set; }
    }

    // ── Reviews ──
    public class CreateReviewRequest
    {
        public Guid ContractId { get; set; }
        public decimal Rating { get; set; }
        public string? Comment { get; set; }
        public int? Quality { get; set; }
        public int? Punctuality { get; set; }
        public int? Communication { get; set; }
        public int? Professionalism { get; set; }
        public int? Compliance { get; set; }
    }

    // ── Favorites ──
    public class AddFavoriteRequest
    {
        public Guid JobId { get; set; }
        public string Type { get; set; } = "JOB";
    }

    // ── Reports ──
    public class CreateReportRequest
    {
        public Guid? ReportedUserId { get; set; }
        public Guid? JobId { get; set; }
        public string Reason { get; set; } = string.Empty;
        public string? Description { get; set; }
    }

    // ── Documents ──
    public class UploadDocumentRequest
    {
        public string Type { get; set; } = string.Empty;
        public string Url { get; set; } = string.Empty;
    }

    // ── Devices ──
    public class RegisterDeviceRequest
    {
        public string FcmToken { get; set; } = string.Empty;
        public string Platform { get; set; } = string.Empty;
        public string? DeviceName { get; set; }
    }

    // ── Blocked Users ──
    public class BlockUserRequest
    {
        public Guid BlockedUserId { get; set; }
        public string? Reason { get; set; }
    }

    // ── Notification Settings ──
    public class UpdateNotifSettingsRequest
    {
        public bool? PushEnabled { get; set; }
        public bool? EmailEnabled { get; set; }
        public bool? NewApplications { get; set; }
        public bool? ApplicationUpdates { get; set; }
        public bool? NewMessages { get; set; }
        public bool? JobReminders { get; set; }
        public bool? Reviews { get; set; }
        public bool? Promotions { get; set; }
    }

    // ── Locations ──
    public class SaveLocationRequest
    {
        public string Label { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty;
        public double Latitude { get; set; }
        public double Longitude { get; set; }
        public bool IsDefault { get; set; }
    }

    // ── Respuesta genérica del API ──
    public class ApiResponse<T>
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public T? Data { get; set; }
        public object? Meta { get; set; }
    }

    public class PaginationMeta
    {
        public int Page { get; set; }
        public int PageSize { get; set; }
        public int Total { get; set; }
        public int TotalPages { get; set; }
    }
}
