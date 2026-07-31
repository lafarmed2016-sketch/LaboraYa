using System.Data;
using Microsoft.Data.SqlClient;

namespace BaseLafarmed2026.Infrastructure
{
    public interface ILaboraYaDb
    {
        IDbConnection CreateConnection();
    }

    public class LaboraYaDbConnection : ILaboraYaDb
    {
        private readonly string _connectionString;
        public LaboraYaDbConnection(string connectionString) => _connectionString = connectionString;
        public IDbConnection CreateConnection() => new SqlConnection(_connectionString);
    }
}
