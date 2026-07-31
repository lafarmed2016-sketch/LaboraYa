using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using BaseLafarmed2026.IServices;

namespace BaseLafarmed2026.Utils
{
    public class LaboraYaJwtService : ILY_JwtService
    {
        private readonly IConfiguration _config;
        public LaboraYaJwtService(IConfiguration config) => _config = config;

        public string GenerateAccessToken(Guid userId, string email, string role)
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["LaboraYa:JwtSecret"]!));
            var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var claims = new[]
            {
                new Claim("sub", userId.ToString()),
                new Claim("email", email),
                new Claim("role", role)
            };
            var token = new JwtSecurityToken(claims: claims, expires: DateTime.UtcNow.AddMinutes(15), signingCredentials: creds);
            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public string GenerateRefreshToken()
        {
            var bytes = new byte[64];
            using var rng = RandomNumberGenerator.Create();
            rng.GetBytes(bytes);
            return Convert.ToBase64String(bytes);
        }
    }

    public class LaboraYaException : Exception
    {
        public LaboraYaException(string message) : base(message) { }
    }
}
