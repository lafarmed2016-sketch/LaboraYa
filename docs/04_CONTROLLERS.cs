// ============================================================================
// LABORAYA API - CONTROLLERS (ASP.NET Core Web API)
// ============================================================================
// Copiar cada controller en: Controllers/
// Todos usan los SPs a través de los Services.
// ============================================================================

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using LaboraYa.API.DTOs;
using LaboraYa.API.Interfaces;
using LaboraYa.API.Services;

namespace LaboraYa.API.Controllers
{
    // ─────────────────────────────────────────────────────────────────────────
    // BASE CONTROLLER - Extrae el UserId del JWT
    // ─────────────────────────────────────────────────────────────────────────
    public class BaseController : ControllerBase
    {
        protected Guid UserId => Guid.Parse(User.FindFirst("sub")?.Value ?? Guid.Empty.ToString());
        protected string UserEmail => User.FindFirst("email")?.Value ?? "";
        protected string UserRole => User.FindFirst("role")?.Value ?? "USER";
        protected string IpAddress => HttpContext.Connection.RemoteIpAddress?.ToString() ?? "";
        protected string UserAgent => Request.Headers["User-Agent"].ToString();
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // AUTH CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/auth")]
    public class AuthController : BaseController
    {
        private readonly IAuthService _auth;
        public AuthController(IAuthService auth) => _auth = auth;

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest req)
        {
            try
            {
                var result = await _auth.Register(req, IpAddress, UserAgent);
                return Ok(new { success = true, message = "Usuario registrado", data = result });
            }
            catch (AppException ex)
            {
                return BadRequest(new { success = false, message = ex.Message });
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest req)
        {
            try
            {
                var result = await _auth.Login(req, IpAddress, UserAgent);
                return Ok(new { success = true, message = "Inicio de sesión exitoso", data = result });
            }
            catch (AppException ex)
            {
                return Unauthorized(new { success = false, message = ex.Message });
            }
        }

        [HttpPost("refresh")]
        public async Task<IActionResult> RefreshToken([FromBody] RefreshTokenRequest req)
        {
            try
            {
                var result = await _auth.RefreshToken(req.RefreshToken);
                return Ok(new { success = true, data = result });
            }
            catch (AppException ex)
            {
                return Unauthorized(new { success = false, message = ex.Message });
            }
        }

        [HttpPost("logout")]
        [Authorize]
        public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest req)
        {
            await _auth.Logout(UserId, req.RefreshToken);
            return Ok(new { success = true, message = "Sesión cerrada" });
        }

        [HttpPost("logout-all")]
        [Authorize]
        public async Task<IActionResult> LogoutAll()
        {
            await _auth.LogoutAll(UserId);
            return Ok(new { success = true, message = "Todas las sesiones cerradas" });
        }

        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest req)
        {
            await _auth.ForgotPassword(req.Email);
            return Ok(new { success = true, message = "Si el correo existe, recibirás instrucciones" });
        }

        [HttpPost("change-password")]
        [Authorize]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest req)
        {
            await _auth.ChangePassword(UserId, req.CurrentPassword, req.NewPassword);
            return Ok(new { success = true, message = "Contraseña actualizada" });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // USERS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/users")]
    [Authorize]
    public class UsersController : BaseController
    {
        private readonly IUserService _users;
        public UsersController(IUserService users) => _users = users;

        [HttpGet("profile")]
        public async Task<IActionResult> GetProfile()
        {
            var user = await _users.GetProfile(UserId);
            if (user == null) return NotFound(new { success = false, message = "Usuario no encontrado" });
            return Ok(new { success = true, data = user });
        }

        [HttpGet("{id}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPublicProfile(Guid id)
        {
            var user = await _users.GetPublicProfile(id);
            if (user == null) return NotFound(new { success = false, message = "Usuario no encontrado" });
            return Ok(new { success = true, data = user });
        }

        [HttpPut("profile")]
        public async Task<IActionResult> UpdateProfile([FromBody] UpdateProfileRequest req)
        {
            var result = await _users.UpdateProfile(UserId, req);
            return Ok(new { success = true, message = result.Message });
        }

        [HttpPut("worker-profile")]
        public async Task<IActionResult> UpdateWorkerProfile([FromBody] UpdateWorkerProfileRequest req)
        {
            var result = await _users.UpdateWorkerProfile(UserId, req);
            return Ok(new { success = true, message = result.Message });
        }

        [HttpDelete("account")]
        public async Task<IActionResult> DeleteAccount()
        {
            var result = await _users.DeleteAccount(UserId);
            return Ok(new { success = true, message = result.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // JOBS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/jobs")]
    public class JobsController : BaseController
    {
        private readonly IJobService _jobs;
        public JobsController(IJobService jobs) => _jobs = jobs;

        [HttpGet]
        public async Task<IActionResult> GetFeed([FromQuery] JobQueryParams query)
        {
            Guid? userId = User.Identity?.IsAuthenticated == true ? UserId : null;
            var (jobs, total, totalPages) = await _jobs.GetFeed(query, userId);
            return Ok(new { success = true, data = jobs, meta = new { page = query.Page, pageSize = query.PageSize, total, totalPages } });
        }

        [HttpGet("nearby")]
        public async Task<IActionResult> GetNearby([FromQuery] double lat, [FromQuery] double lng, [FromQuery] double radius = 10, [FromQuery] int page = 1)
        {
            var jobs = await _jobs.GetNearby(lat, lng, radius, page, 20);
            return Ok(new { success = true, data = jobs });
        }

        [HttpGet("mine")]
        [Authorize]
        public async Task<IActionResult> GetMine([FromQuery] string? status, [FromQuery] int page = 1)
        {
            var jobs = await _jobs.GetMine(UserId, status, page, 20);
            return Ok(new { success = true, data = jobs });
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetById(Guid id)
        {
            Guid? userId = User.Identity?.IsAuthenticated == true ? UserId : null;
            var (job, images) = await _jobs.GetById(id, userId);
            if (job == null) return NotFound(new { success = false, message = "Trabajo no encontrado" });
            return Ok(new { success = true, data = new { job, images } });
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> Create([FromBody] CreateJobRequest req)
        {
            var result = await _jobs.Create(UserId, req);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message, data = new { jobId = result.JobId } });
        }

        [HttpPut("{id}")]
        [Authorize]
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateJobRequest req)
        {
            var result = await _jobs.Update(id, UserId, req);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message });
        }

        [HttpDelete("{id}")]
        [Authorize]
        public async Task<IActionResult> Delete(Guid id)
        {
            var result = await _jobs.Delete(id, UserId);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // APPLICATIONS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/applications")]
    [Authorize]
    public class ApplicationsController : BaseController
    {
        private readonly IApplicationService _apps;
        public ApplicationsController(IApplicationService apps) => _apps = apps;

        [HttpPost]
        public async Task<IActionResult> Apply([FromBody] ApplyRequest req)
        {
            var result = await _apps.Apply(UserId, req);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message, data = new { applicationId = result.ApplicationId } });
        }

        [HttpGet("mine")]
        public async Task<IActionResult> GetMine([FromQuery] int page = 1)
        {
            var apps = await _apps.GetMine(UserId, page, 20);
            return Ok(new { success = true, data = apps });
        }

        [HttpGet("job/{jobId}")]
        public async Task<IActionResult> GetByJob(Guid jobId)
        {
            var apps = await _apps.GetByJob(jobId, UserId);
            return Ok(new { success = true, data = apps });
        }

        [HttpPut("{id}/accept")]
        public async Task<IActionResult> Accept(Guid id)
        {
            var result = await _apps.Accept(id, UserId);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message, data = new { contractId = result.ContractId } });
        }

        [HttpPut("{id}/reject")]
        public async Task<IActionResult> Reject(Guid id)
        {
            var result = await _apps.Reject(id, UserId);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message });
        }

        [HttpPut("{id}/withdraw")]
        public async Task<IActionResult> Withdraw(Guid id)
        {
            var result = await _apps.Withdraw(id, UserId);
            return Ok(new { success = true, message = result.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CONTRACTS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/contracts")]
    [Authorize]
    public class ContractsController : BaseController
    {
        private readonly IContractService _contracts;
        public ContractsController(IContractService contracts) => _contracts = contracts;

        [HttpGet]
        public async Task<IActionResult> GetMine([FromQuery] string? status, [FromQuery] int page = 1)
        {
            var contracts = await _contracts.GetMine(UserId, status, page, 20);
            return Ok(new { success = true, data = contracts });
        }

        [HttpPut("{id}/status")]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] UpdateContractStatusRequest req)
        {
            var result = await _contracts.UpdateStatus(id, UserId, req);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CHAT CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/chats")]
    [Authorize]
    public class ChatsController : BaseController
    {
        private readonly IChatService _chat;
        public ChatsController(IChatService chat) => _chat = chat;

        [HttpGet]
        public async Task<IActionResult> GetConversations()
        {
            var convs = await _chat.GetConversations(UserId);
            return Ok(new { success = true, data = convs });
        }

        [HttpPost]
        public async Task<IActionResult> CreateConversation([FromBody] CreateConversationRequest req)
        {
            var result = await _chat.GetOrCreateConversation(UserId, req.OtherUserId, req.JobId);
            return Ok(new { success = true, data = new { conversationId = result.ConversationId } });
        }

        [HttpGet("{id}/messages")]
        public async Task<IActionResult> GetMessages(Guid id, [FromQuery] int page = 1)
        {
            var messages = await _chat.GetMessages(id, UserId, page, 50);
            return Ok(new { success = true, data = messages });
        }

        [HttpPost("{id}/messages")]
        public async Task<IActionResult> SendMessage(Guid id, [FromBody] SendMessageRequest req)
        {
            var result = await _chat.SendMessage(id, UserId, req);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, data = new { messageId = result.MessageId } });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // NOTIFICATIONS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/notifications")]
    [Authorize]
    public class NotificationsController : BaseController
    {
        private readonly INotificationService _notifs;
        public NotificationsController(INotificationService notifs) => _notifs = notifs;

        [HttpGet]
        public async Task<IActionResult> Get([FromQuery] int page = 1)
        {
            var notifs = await _notifs.Get(UserId, page, 30);
            return Ok(new { success = true, data = notifs });
        }

        [HttpGet("unread-count")]
        public async Task<IActionResult> UnreadCount()
        {
            var count = await _notifs.GetUnreadCount(UserId);
            return Ok(new { success = true, data = new { count } });
        }

        [HttpPut("{id}/read")]
        public async Task<IActionResult> MarkRead(Guid id)
        {
            await _notifs.MarkRead(id, UserId);
            return Ok(new { success = true });
        }

        [HttpPut("read-all")]
        public async Task<IActionResult> MarkAllRead()
        {
            await _notifs.MarkAllRead(UserId);
            return Ok(new { success = true });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REVIEWS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/reviews")]
    [Authorize]
    public class ReviewsController : BaseController
    {
        private readonly IReviewService _reviews;
        public ReviewsController(IReviewService reviews) => _reviews = reviews;

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateReviewRequest req)
        {
            var result = await _reviews.Create(UserId, req);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message, data = new { reviewId = result.ReviewId } });
        }

        [HttpGet("user/{userId}")]
        [AllowAnonymous]
        public async Task<IActionResult> GetByUser(Guid userId, [FromQuery] int page = 1)
        {
            var reviews = await _reviews.GetByUser(userId, page, 20);
            return Ok(new { success = true, data = reviews });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // FAVORITES CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/favorites")]
    [Authorize]
    public class FavoritesController : BaseController
    {
        private readonly IFavoriteService _favs;
        public FavoritesController(IFavoriteService favs) => _favs = favs;

        [HttpGet]
        public async Task<IActionResult> GetMine([FromQuery] int page = 1)
        {
            var favs = await _favs.GetMine(UserId, page, 20);
            return Ok(new { success = true, data = favs });
        }

        [HttpPost]
        public async Task<IActionResult> Add([FromBody] AddFavoriteRequest req)
        {
            var result = await _favs.Add(UserId, req);
            return Ok(new { success = true, message = result.Message });
        }

        [HttpDelete("{jobId}")]
        public async Task<IActionResult> Remove(Guid jobId)
        {
            var result = await _favs.Remove(UserId, jobId);
            return Ok(new { success = true, message = result.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // CATEGORIES CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/categories")]
    public class CategoriesController : BaseController
    {
        private readonly ICategoryService _cats;
        public CategoriesController(ICategoryService cats) => _cats = cats;

        [HttpGet]
        public async Task<IActionResult> GetAll()
        {
            var categories = await _cats.GetAll();
            return Ok(new { success = true, data = categories });
        }

        [HttpGet("{id}/subcategories")]
        public async Task<IActionResult> GetSubcategories(Guid id)
        {
            var subs = await _cats.GetSubcategories(id);
            return Ok(new { success = true, data = subs });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // REPORTS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/reports")]
    [Authorize]
    public class ReportsController : BaseController
    {
        private readonly IReportService _reports;
        public ReportsController(IReportService reports) => _reports = reports;

        [HttpPost]
        public async Task<IActionResult> Create([FromBody] CreateReportRequest req)
        {
            var result = await _reports.Create(UserId, req);
            return Ok(new { success = true, message = result.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // VERIFICATIONS CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/verifications")]
    [Authorize]
    public class VerificationsController : BaseController
    {
        private readonly IDocumentService _docs;
        public VerificationsController(IDocumentService docs) => _docs = docs;

        [HttpGet]
        public async Task<IActionResult> GetStatus()
        {
            var docs = await _docs.GetStatus(UserId);
            return Ok(new { success = true, data = docs });
        }

        [HttpPost]
        public async Task<IActionResult> Upload([FromBody] UploadDocumentRequest req)
        {
            var result = await _docs.Upload(UserId, req);
            if (result.Success == 0) return BadRequest(new { success = false, message = result.Message });
            return Ok(new { success = true, message = result.Message });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // DEVICES CONTROLLER
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/devices")]
    [Authorize]
    public class DevicesController : BaseController
    {
        private readonly IDeviceService _devices;
        public DevicesController(IDeviceService devices) => _devices = devices;

        [HttpPost]
        public async Task<IActionResult> Register([FromBody] RegisterDeviceRequest req)
        {
            await _devices.Register(UserId, req);
            return Ok(new { success = true });
        }

        [HttpDelete("{fcmToken}")]
        public async Task<IActionResult> Deactivate(string fcmToken)
        {
            await _devices.Deactivate(UserId, fcmToken);
            return Ok(new { success = true });
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════
    // SETTINGS CONTROLLER (NotifSettings + BlockedUsers + Locations)
    // ═══════════════════════════════════════════════════════════════════════════
    [ApiController]
    [Route("api/v1/settings")]
    [Authorize]
    public class SettingsController : BaseController
    {
        private readonly INotificationSettingsService _notifSettings;
        private readonly IBlockedUserService _blocked;
        private readonly ILocationService _locations;

        public SettingsController(INotificationSettingsService ns, IBlockedUserService b, ILocationService l)
        {
            _notifSettings = ns; _blocked = b; _locations = l;
        }

        [HttpGet("notifications")]
        public async Task<IActionResult> GetNotifSettings()
        {
            var settings = await _notifSettings.Get(UserId);
            return Ok(new { success = true, data = settings });
        }

        [HttpPut("notifications")]
        public async Task<IActionResult> UpdateNotifSettings([FromBody] UpdateNotifSettingsRequest req)
        {
            await _notifSettings.Update(UserId, req);
            return Ok(new { success = true, message = "Configuración actualizada" });
        }

        [HttpGet("blocked-users")]
        public async Task<IActionResult> GetBlockedUsers()
        {
            var list = await _blocked.GetList(UserId);
            return Ok(new { success = true, data = list });
        }

        [HttpPost("blocked-users")]
        public async Task<IActionResult> BlockUser([FromBody] BlockUserRequest req)
        {
            var result = await _blocked.Block(UserId, req);
            return Ok(new { success = true, message = result.Message });
        }

        [HttpDelete("blocked-users/{blockedUserId}")]
        public async Task<IActionResult> UnblockUser(Guid blockedUserId)
        {
            var result = await _blocked.Unblock(UserId, blockedUserId);
            return Ok(new { success = true, message = result.Message });
        }

        [HttpGet("locations")]
        public async Task<IActionResult> GetLocations()
        {
            var locations = await _locations.GetMine(UserId);
            return Ok(new { success = true, data = locations });
        }

        [HttpPost("locations")]
        public async Task<IActionResult> SaveLocation([FromBody] SaveLocationRequest req)
        {
            var result = await _locations.Save(UserId, req);
            return Ok(new { success = true, message = result.Message });
        }

        [HttpDelete("locations/{id}")]
        public async Task<IActionResult> DeleteLocation(Guid id)
        {
            await _locations.Delete(UserId, id);
            return Ok(new { success = true });
        }
    }
}
