using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrafficManagerWeb.Library.Entities;

namespace TrafficManagerWeb.Library.DataAccess.Interfaces
{
    public interface ILogDataAccess
    {
        Task<List<LogEntity>> GetLogEntitiesAsync();
        Task AddLogEntityAsync(LogEntity entity);
    }
}
