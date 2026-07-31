using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using BaseLafarmed2026.Common;
using BaseLafarmed2026.IServices;
using BaseLafarmed2026.Utils;

namespace BaseLafarmed2026.Controllers
{
    // ══════════ BASE (helper) ══════════
    public class LYBase : ControllerBase
    {
        protected Guid UserId => Guid.Parse(User.FindFirst("sub")?.Value ?? Guid.Empty.ToString());
        protected string Ip => HttpContext.Connection.RemoteIpAddress?.ToString() ?? "";
        protected string UA => Request.Headers["User-Agent"].ToString();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // LABORAYA - CONTROLLER ÚNICO (Todo agrupado bajo "LaboraYa" en Swagger)
    // ══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/LaboraYa")]
    [Tags("LaboraYa")]
    public class LaboraYaController : LYBase
    {
        private readonly ILY_AuthService _auth;
        private readonly ILY_UserService _users;
        private readonly ILY_JobService _jobs;
        private readonly ILY_ApplicationService _apps;
        private readonly ILY_ContractService _contracts;
        private readonly ILY_ChatService _chat;
        private readonly ILY_NotificationService _notifs;
        private readonly ILY_ReviewService _reviews;
        private readonly ILY_FavoriteService _favs;
        private readonly ILY_CategoryService _cats;
        private readonly ILY_ReportService _reports;
        private readonly ILY_DocumentService _docs;
        private readonly ILY_DeviceService _devices;
        private readonly ILY_BlockedUserService _blocked;
        private readonly ILY_NotifSettingsService _notifSettings;

        public LaboraYaController(
            ILY_AuthService auth, ILY_UserService users, ILY_JobService jobs,
            ILY_ApplicationService apps, ILY_ContractService contracts, ILY_ChatService chat,
            ILY_NotificationService notifs, ILY_ReviewService reviews, ILY_FavoriteService favs,
            ILY_CategoryService cats, ILY_ReportService reports, ILY_DocumentService docs,
            ILY_DeviceService devices, ILY_BlockedUserService blocked, ILY_NotifSettingsService notifSettings)
        {
            _auth = auth; _users = users; _jobs = jobs; _apps = apps; _contracts = contracts;
            _chat = chat; _notifs = notifs; _reviews = reviews; _favs = favs; _cats = cats;
            _reports = reports; _docs = docs; _devices = devices; _blocked = blocked; _notifSettings = notifSettings;
        }

        // ─── AUTH ───
        [HttpPost("auth/register")]
        public async Task<IActionResult> Register([FromBody] LY_RegisterRequest req)
        { try { return Ok(new { success = true, data = await _auth.Register(req, Ip, UA) }); } catch (LaboraYaException ex) { return BadRequest(new { success = false, message = ex.Message }); } }

        [HttpPost("auth/login")]
        public async Task<IActionResult> Login([FromBody] LY_LoginRequest req)
        { try { return Ok(new { success = true, data = await _auth.Login(req, Ip, UA) }); } catch (LaboraYaException ex) { return Unauthorized(new { success = false, message = ex.Message }); } }

        [HttpPost("auth/refresh")]
        public async Task<IActionResult> Refresh([FromBody] LY_RefreshTokenRequest req)
        { try { return Ok(new { success = true, data = await _auth.RefreshToken(req.RefreshToken) }); } catch (LaboraYaException ex) { return Unauthorized(new { success = false, message = ex.Message }); } }

        [HttpPost("auth/logout"), Authorize]
        public async Task<IActionResult> Logout([FromBody] LY_RefreshTokenRequest req)
        { await _auth.Logout(UserId, req.RefreshToken); return Ok(new { success = true }); }

        [HttpPost("auth/change-password"), Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] LY_ChangePasswordRequest req)
        { await _auth.ChangePassword(UserId, req.NewPassword); return Ok(new { success = true }); }

        // ─── USERS ───
        [HttpGet("users/profile"), Authorize]
        public async Task<IActionResult> GetProfile() => Ok(new { success = true, data = await _users.GetProfile(UserId) });

        [HttpGet("users/{id}")]
        public async Task<IActionResult> GetUser(Guid id) => Ok(new { success = true, data = await _users.GetProfile(id) });

        [HttpPut("users/profile"), Authorize]
        public async Task<IActionResult> UpdateProfile([FromBody] LY_UpdateProfileRequest req) => Ok(new { success = true, message = (await _users.UpdateProfile(UserId, req)).Message });

        [HttpPut("users/worker-profile"), Authorize]
        public async Task<IActionResult> UpdateWorker([FromBody] LY_UpdateWorkerProfileRequest req) => Ok(new { success = true, message = (await _users.UpdateWorkerProfile(UserId, req)).Message });

        [HttpDelete("users/account"), Authorize]
        public async Task<IActionResult> DeleteAccount() => Ok(new { success = true, message = (await _users.DeleteAccount(UserId)).Message });

        // ─── JOBS ───
        [HttpGet("jobs")]
        public async Task<IActionResult> GetJobs([FromQuery] LY_JobQueryParams q) { var (jobs, total, pages) = await _jobs.GetFeed(q, null); return Ok(new { success = true, data = jobs, meta = new { q.Page, q.PageSize, total, totalPages = pages } }); }

        [HttpGet("jobs/nearby")]
        public async Task<IActionResult> GetNearby([FromQuery] double lat, [FromQuery] double lng, [FromQuery] double radius = 10, [FromQuery] int page = 1) => Ok(new { success = true, data = await _jobs.GetNearby(lat, lng, radius, page) });

        [HttpGet("jobs/mine"), Authorize]
        public async Task<IActionResult> GetMyJobs([FromQuery] string? status, [FromQuery] int page = 1) => Ok(new { success = true, data = await _jobs.GetMine(UserId, status, page) });

        [HttpGet("jobs/{id}")]
        public async Task<IActionResult> GetJob(Guid id) { var (job, images) = await _jobs.GetById(id, null); return job == null ? NotFound(new { success = false }) : Ok(new { success = true, data = new { job, images } }); }

        [HttpPost("jobs"), Authorize]
        public async Task<IActionResult> CreateJob([FromBody] LY_CreateJobRequest req) { var r = await _jobs.Create(UserId, req); return r.Success == 0 ? BadRequest(new { success = false, message = r.Message }) : Ok(new { success = true, data = new { jobId = r.JobId } }); }

        [HttpPut("jobs/{id}"), Authorize]
        public async Task<IActionResult> UpdateJob(Guid id, [FromBody] LY_UpdateJobRequest req) { var r = await _jobs.Update(id, UserId, req); return Ok(new { success = r.Success == 1, message = r.Message }); }

        [HttpDelete("jobs/{id}"), Authorize]
        public async Task<IActionResult> DeleteJob(Guid id) { var r = await _jobs.Delete(id, UserId); return Ok(new { success = r.Success == 1, message = r.Message }); }

        // ─── APPLICATIONS ───
        [HttpPost("applications"), Authorize]
        public async Task<IActionResult> Apply([FromBody] LY_ApplyRequest req) { var r = await _apps.Apply(UserId, req); return r.Success == 0 ? BadRequest(new { success = false, message = r.Message }) : Ok(new { success = true, data = new { applicationId = r.ApplicationId } }); }

        [HttpGet("applications/mine"), Authorize]
        public async Task<IActionResult> MyApplications([FromQuery] int page = 1) => Ok(new { success = true, data = await _apps.GetMine(UserId, page) });

        [HttpGet("applications/job/{jobId}"), Authorize]
        public async Task<IActionResult> JobApplications(Guid jobId) => Ok(new { success = true, data = await _apps.GetByJob(jobId, UserId) });

        [HttpPut("applications/{id}/accept"), Authorize]
        public async Task<IActionResult> AcceptApp(Guid id) { var r = await _apps.Accept(id, UserId); return Ok(new { success = r.Success == 1, message = r.Message, contractId = r.ContractId }); }

        [HttpPut("applications/{id}/reject"), Authorize]
        public async Task<IActionResult> RejectApp(Guid id) { var r = await _apps.Reject(id, UserId); return Ok(new { success = r.Success == 1, message = r.Message }); }

        // ─── CONTRACTS ───
        [HttpGet("contracts"), Authorize]
        public async Task<IActionResult> GetContracts([FromQuery] string? status, [FromQuery] int page = 1) => Ok(new { success = true, data = await _contracts.GetMine(UserId, status, page) });

        [HttpPut("contracts/{id}/status"), Authorize]
        public async Task<IActionResult> UpdateContract(Guid id, [FromBody] LY_UpdateContractStatusRequest req) { var r = await _contracts.UpdateStatus(id, UserId, req); return Ok(new { success = r.Success == 1, message = r.Message }); }

        // ─── CHAT ───
        [HttpGet("chats"), Authorize]
        public async Task<IActionResult> GetChats() => Ok(new { success = true, data = await _chat.GetConversations(UserId) });

        [HttpPost("chats"), Authorize]
        public async Task<IActionResult> CreateChat([FromBody] LY_CreateConversationRequest req) { var r = await _chat.GetOrCreate(UserId, req.OtherUserId, req.JobId); return Ok(new { success = true, conversationId = r.ConversationId }); }

        [HttpGet("chats/{id}/messages"), Authorize]
        public async Task<IActionResult> GetMessages(Guid id, [FromQuery] int page = 1) => Ok(new { success = true, data = await _chat.GetMessages(id, UserId, page) });

        [HttpPost("chats/{id}/messages"), Authorize]
        public async Task<IActionResult> SendMsg(Guid id, [FromBody] LY_SendMessageRequest req) { var r = await _chat.SendMessage(id, UserId, req); return Ok(new { success = true, messageId = r.MessageId }); }

        // ─── NOTIFICATIONS ───
        [HttpGet("notifications"), Authorize]
        public async Task<IActionResult> GetNotifs([FromQuery] int page = 1) => Ok(new { success = true, data = await _notifs.Get(UserId, page) });

        [HttpGet("notifications/unread-count"), Authorize]
        public async Task<IActionResult> UnreadCount() => Ok(new { success = true, count = await _notifs.GetUnreadCount(UserId) });

        [HttpPut("notifications/{id}/read"), Authorize]
        public async Task<IActionResult> MarkRead(Guid id) { await _notifs.MarkRead(id, UserId); return Ok(new { success = true }); }

        [HttpPut("notifications/read-all"), Authorize]
        public async Task<IActionResult> MarkAllRead() { await _notifs.MarkAllRead(UserId); return Ok(new { success = true }); }

        // ─── REVIEWS ───
        [HttpPost("reviews"), Authorize]
        public async Task<IActionResult> CreateReview([FromBody] LY_CreateReviewRequest req) { var r = await _reviews.Create(UserId, req); return Ok(new { success = r.Success == 1, message = r.Message }); }

        [HttpGet("reviews/user/{userId}")]
        public async Task<IActionResult> GetReviews(Guid userId, [FromQuery] int page = 1) => Ok(new { success = true, data = await _reviews.GetByUser(userId, page) });

        // ─── FAVORITES ───
        [HttpGet("favorites"), Authorize]
        public async Task<IActionResult> GetFavs([FromQuery] int page = 1) => Ok(new { success = true, data = await _favs.GetMine(UserId, page) });

        [HttpPost("favorites"), Authorize]
        public async Task<IActionResult> AddFav([FromBody] LY_AddFavoriteRequest req) => Ok(new { success = true, message = (await _favs.Add(UserId, req)).Message });

        [HttpDelete("favorites/{jobId}"), Authorize]
        public async Task<IActionResult> RemoveFav(Guid jobId) => Ok(new { success = true, message = (await _favs.Remove(UserId, jobId)).Message });

        // ─── CATEGORIES ───
        [HttpGet("categories")]
        public async Task<IActionResult> GetCategories() => Ok(new { success = true, data = await _cats.GetAll() });

        // ─── REPORTS ───
        [HttpPost("reports"), Authorize]
        public async Task<IActionResult> CreateReport([FromBody] LY_CreateReportRequest req) => Ok(new { success = true, message = (await _reports.Create(UserId, req)).Message });

        // ─── VERIFICATIONS ───
        [HttpGet("verifications"), Authorize]
        public async Task<IActionResult> GetDocs() => Ok(new { success = true, data = await _docs.GetStatus(UserId) });

        [HttpPost("verifications"), Authorize]
        public async Task<IActionResult> UploadDoc([FromBody] LY_UploadDocumentRequest req) { var r = await _docs.Upload(UserId, req); return Ok(new { success = r.Success == 1, message = r.Message }); }

        // ─── DEVICES ───
        [HttpPost("devices"), Authorize]
        public async Task<IActionResult> RegisterDevice([FromBody] LY_RegisterDeviceRequest req) { await _devices.Register(UserId, req); return Ok(new { success = true }); }

        // ─── SETTINGS ───
        [HttpGet("settings/notifications"), Authorize]
        public async Task<IActionResult> GetNotifSettings() => Ok(new { success = true, data = await _notifSettings.Get(UserId) });

        [HttpPut("settings/notifications"), Authorize]
        public async Task<IActionResult> UpdateNotifSettings([FromBody] LY_UpdateNotifSettingsRequest req) => Ok(new { success = true, message = (await _notifSettings.Update(UserId, req)).Message });

        [HttpGet("settings/blocked-users"), Authorize]
        public async Task<IActionResult> GetBlocked() => Ok(new { success = true, data = await _blocked.GetList(UserId) });

        [HttpPost("settings/blocked-users"), Authorize]
        public async Task<IActionResult> BlockUser([FromBody] LY_BlockUserRequest req) => Ok(new { success = true, message = (await _blocked.Block(UserId, req)).Message });

        [HttpDelete("settings/blocked-users/{blockedUserId}"), Authorize]
        public async Task<IActionResult> UnblockUser(Guid blockedUserId) => Ok(new { success = true, message = (await _blocked.Unblock(UserId, blockedUserId)).Message });
    }
}
