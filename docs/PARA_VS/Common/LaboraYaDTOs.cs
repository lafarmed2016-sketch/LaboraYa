namespace BaseLafarmed2026.Common
{
    public class LY_RegisterRequest
    {
        public string FirstName { get; set; } = "";
        public string LastName { get; set; } = "";
        public string Email { get; set; } = "";
        public string? Phone { get; set; }
        public string Password { get; set; } = "";
        public string UserType { get; set; } = "BOTH";
        public string? City { get; set; }
    }

    public class LY_LoginRequest
    {
        public string Email { get; set; } = "";
        public string Password { get; set; } = "";
    }

    public class LY_RefreshTokenRequest { public string RefreshToken { get; set; } = ""; }
    public class LY_ChangePasswordRequest { public string NewPassword { get; set; } = ""; }

    public class LY_AuthResponse
    {
        public string AccessToken { get; set; } = "";
        public string RefreshToken { get; set; } = "";
        public object? User { get; set; }
    }

    public class LY_UpdateProfileRequest
    {
        public string? FirstName { get; set; }
        public string? LastName { get; set; }
        public string? Phone { get; set; }
        public string? City { get; set; }
        public string? Bio { get; set; }
        public string? Avatar { get; set; }
    }

    public class LY_UpdateWorkerProfileRequest
    {
        public string? Description { get; set; }
        public int? YearsExperience { get; set; }
        public bool? Available { get; set; }
        public double? RadiusKm { get; set; }
        public decimal? HourlyRate { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
    }

    public class LY_CreateJobRequest
    {
        public Guid CategoryId { get; set; }
        public string Title { get; set; } = "";
        public string Description { get; set; } = "";
        public string? Address { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public string? Duration { get; set; }
        public int WorkersNeeded { get; set; } = 1;
        public string Materials { get; set; } = "TO_COORDINATE";
        public string Modality { get; set; } = "";
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool BudgetFixed { get; set; }
        public bool IsUrgent { get; set; }
        public bool IsRemote { get; set; }
        public bool PublishNow { get; set; } = true;
    }

    public class LY_UpdateJobRequest
    {
        public string? Title { get; set; }
        public string? Description { get; set; }
        public string? Address { get; set; }
        public decimal? BudgetMin { get; set; }
        public decimal? BudgetMax { get; set; }
        public bool? IsUrgent { get; set; }
        public string? Status { get; set; }
    }

    public class LY_JobQueryParams
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

    public class LY_ApplyRequest
    {
        public Guid JobId { get; set; }
        public string? Message { get; set; }
        public decimal? ProposedBudget { get; set; }
        public string? EstimatedTime { get; set; }
    }

    public class LY_UpdateContractStatusRequest { public string Status { get; set; } = ""; public string? Note { get; set; } }
    public class LY_CreateConversationRequest { public Guid OtherUserId { get; set; } public Guid? JobId { get; set; } }
    public class LY_SendMessageRequest { public string Content { get; set; } = ""; public string Type { get; set; } = "TEXT"; }
    public class LY_CreateReviewRequest { public Guid ContractId { get; set; } public decimal Rating { get; set; } public string? Comment { get; set; } }
    public class LY_AddFavoriteRequest { public Guid JobId { get; set; } }
    public class LY_CreateReportRequest { public Guid? ReportedUserId { get; set; } public Guid? JobId { get; set; } public string Reason { get; set; } = ""; public string? Description { get; set; } }
    public class LY_UploadDocumentRequest { public string Type { get; set; } = ""; public string Url { get; set; } = ""; }
    public class LY_RegisterDeviceRequest { public string FcmToken { get; set; } = ""; public string Platform { get; set; } = ""; }
    public class LY_BlockUserRequest { public Guid BlockedUserId { get; set; } }
    public class LY_UpdateNotifSettingsRequest { public bool? PushEnabled { get; set; } public bool? NewMessages { get; set; } public bool? Reviews { get; set; } }
}
