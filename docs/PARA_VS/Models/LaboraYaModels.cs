namespace BaseLafarmed2026.Models
{
    // ══════════ RESULTADO DE STORED PROCEDURES ══════════
    public class SpResult
    {
        public int Success { get; set; }
        public string Message { get; set; } = "";
        public Guid? UserId { get; set; }
        public Guid? JobId { get; set; }
        public Guid? ApplicationId { get; set; }
        public Guid? ContractId { get; set; }
        public Guid? MessageId { get; set; }
        public Guid? ReviewId { get; set; }
        public Guid? ConversationId { get; set; }
    }

    // ══════════ USER ══════════
    public class UserEntity
    {
        public Guid Id { get; set; }
        public string Email { get; set; } = "";
        public string? Phone { get; set; }
        public string? PasswordHash { get; set; }
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string? Avatar { get; set; }
        public string Role { get; set; } = "USER";
        public string UserType { get; set; } = "BOTH";
        public string Status { get; set; } = "ACTIVE";
        public bool EmailVerified { get; set; }
        public bool PhoneVerified { get; set; }
        public string? City { get; set; }
        public string? Bio { get; set; }
        public DateTime CreatedAt { get; set; }
        public int LoginAttempts { get; set; }
        // Worker
        public string? WorkerDescription { get; set; }
        public int? YearsExperience { get; set; }
        public bool? Available { get; set; }
        public double? RadiusKm { get; set; }
        public decimal? HourlyRate { get; set; }
        public int? CompletedJobs { get; set; }
        public decimal? WorkerRating { get; set; }
        public int? WorkerReviews { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        // Employer
        public string? CompanyName { get; set; }
        public decimal? EmployerRating { get; set; }
        public int? EmployerReviews { get; set; }
        public bool? EmployerVerified { get; set; }
    }

    // ══════════ JOB ══════════
    public class JobEntity
    {
        public Guid Id { get; set; }
        public string Title { get; set; } = "";
        public string Description { get; set; } = "";
        public string? Address { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string Modality { get; set; } = "";
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
        public Guid CategoryId { get; set; }
        public string CategoryName { get; set; } = "";
        public string? CategoryIcon { get; set; }
        public Guid PublisherId { get; set; }
        public string PublisherFirstName { get; set; } = "";
        public string PublisherLastName { get; set; } = "";
        public string? PublisherAvatar { get; set; }
        public int? TotalCount { get; set; }
        public int? TotalPages { get; set; }
        public double? DistanceKm { get; set; }
    }

    public class JobImageEntity
    {
        public Guid Id { get; set; }
        public string Url { get; set; } = "";
        public int SortOrder { get; set; }
    }

    // ══════════ APPLICATION ══════════
    public class ApplicationEntity
    {
        public Guid Id { get; set; }
        public string? Message { get; set; }
        public decimal? ProposedBudget { get; set; }
        public string? EstimatedTime { get; set; }
        public string Status { get; set; } = "SENT";
        public DateTime CreatedAt { get; set; }
        public Guid ApplicantId { get; set; }
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Avatar { get; set; }
        public decimal? AverageRating { get; set; }
        public int? TotalReviews { get; set; }
        public int? CompletedJobs { get; set; }
        // Para GetMine
        public Guid? JobId { get; set; }
        public string? Title { get; set; }
        public string? JobStatus { get; set; }
        public string? Modality { get; set; }
        public string? CategoryName { get; set; }
    }

    // ══════════ CONTRACT ══════════
    public class ContractEntity
    {
        public Guid Id { get; set; }
        public string Status { get; set; } = "PENDING";
        public decimal? AgreedBudget { get; set; }
        public string PaymentMethod { get; set; } = "TO_COORDINATE";
        public DateTime CreatedAt { get; set; }
        public Guid JobId { get; set; }
        public string? JobTitle { get; set; }
        public string? OtherFirstName { get; set; }
        public string? OtherLastName { get; set; }
        public string? OtherAvatar { get; set; }
        public string? MyRole { get; set; }
    }

    // ══════════ CHAT ══════════
    public class ConversationEntity
    {
        public Guid ConversationId { get; set; }
        public Guid ParticipantId { get; set; }
        public string ParticipantFirstName { get; set; } = "";
        public string ParticipantLastName { get; set; } = "";
        public string? ParticipantAvatar { get; set; }
        public string? LastMessage { get; set; }
        public DateTime? LastMessageAt { get; set; }
        public int UnreadCount { get; set; }
    }

    public class MessageEntity
    {
        public Guid Id { get; set; }
        public string? Content { get; set; }
        public string Type { get; set; } = "TEXT";
        public Guid SenderId { get; set; }
        public DateTime CreatedAt { get; set; }
        public string SenderFirstName { get; set; } = "";
        public string SenderLastName { get; set; } = "";
        public string? SenderAvatar { get; set; }
    }

    // ══════════ OTHERS ══════════
    public class ReviewEntity
    {
        public Guid Id { get; set; }
        public decimal Rating { get; set; }
        public string? Comment { get; set; }
        public DateTime CreatedAt { get; set; }
        public string ReviewerFirstName { get; set; } = "";
        public string ReviewerLastName { get; set; } = "";
        public string? ReviewerAvatar { get; set; }
        public string? JobTitle { get; set; }
    }

    public class NotificationEntity
    {
        public Guid Id { get; set; }
        public string Type { get; set; } = "";
        public string Title { get; set; } = "";
        public string Body { get; set; } = "";
        public string? Data { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class FavoriteEntity
    {
        public Guid FavoriteId { get; set; }
        public Guid JobId { get; set; }
        public string Title { get; set; } = "";
        public string Modality { get; set; } = "";
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool IsUrgent { get; set; }
        public string? Address { get; set; }
        public string CategoryName { get; set; } = "";
    }

    public class CategoryEntity
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = "";
        public string? Description { get; set; }
        public string? Icon { get; set; }
        public int SortOrder { get; set; }
    }

    public class DocumentEntity
    {
        public Guid Id { get; set; }
        public string Type { get; set; } = "";
        public string Status { get; set; } = "PENDING";
        public string? Note { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class BlockedUserEntity
    {
        public Guid BlockedUserId { get; set; }
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string? Avatar { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    public class NotificationSettingsEntity
    {
        public bool PushEnabled { get; set; }
        public bool EmailEnabled { get; set; }
        public bool NewApplications { get; set; }
        public bool NewMessages { get; set; }
        public bool Reviews { get; set; }
    }
}
