using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.WindowsAzure;
using TrafficManagerWeb.Library.DataAccess.Interfaces;
using TrafficManagerWeb.Library.Entities;

namespace TrafficManagerWeb.Library.DataAccess
{
    public class SqlLogDataDal : ILogDataAccess
    {
        private SqlLogDataDbContext _dbContext;

        public SqlLogDataDal()
        {
            _dbContext = new SqlLogDataDbContext();
        }

        public Task<List<Entities.LogEntity>> GetLogEntitiesAsync()
        {
            return Task.Run<List<Entities.LogEntity>>(() =>
            {
                var logEntities = _dbContext.LogEntries.ToList();
                return logEntities;
            });
        }

        public Task AddLogEntityAsync(Entities.LogEntity entity)
        {
            return Task.Run(() =>
            {
                _dbContext.LogEntries.Add(entity);
                _dbContext.SaveChanges();
            });
        }
    }

    internal class SqlLogDataDbContext : DbContext
    {
        public DbSet<LogEntity> LogEntries { get; set; }

        public SqlLogDataDbContext()
            : base("name=TrafficManagerSample.LogDataStorageConnection")
        {
        }
    }
}
