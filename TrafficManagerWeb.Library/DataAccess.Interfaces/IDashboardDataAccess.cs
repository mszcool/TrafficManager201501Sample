using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrafficManagerWeb.Library.Entities;

namespace TrafficManagerWeb.Library.DataAccess.Interfaces
{
    public interface IDashboardDataAccess
    {
        string RegionName { get; }
        string DeploymentName { get; }

        Task<List<ServiceDashboardEntity>> GetDashboardRecordsAsync();
        Task UpdateDashboardRecordAsync(ServiceDashboardEntity recordToUpdate);
    }
}
