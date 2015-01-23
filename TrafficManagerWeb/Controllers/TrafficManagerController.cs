using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using TrafficManagerWeb.Library.DataAccess.Interfaces;
using TrafficManagerWeb.Library.Entities;

namespace TrafficManagerWeb.Controllers
{
    public class TrafficManagerController : Controller
    {
        private readonly IDashboardDataAccess _dashboardDataAccess;
        private readonly ILogDataAccess _logDataAccess;

        public TrafficManagerController(IDashboardDataAccess dashboardDataAccess, ILogDataAccess logDataAccess)
            : base()
        {
            _logDataAccess = logDataAccess;
            _dashboardDataAccess = dashboardDataAccess;
        }

        //
        // Ping URL for traffic manager, needs to respond in 5s with http 200 OK
        //
        public async Task<ActionResult> Ping()
        {
            // First of all get the dashboard item from the table
            var dashboardItem = await GetDashboardItemForDeployment();

            // Try to write the log-entry into the database. If that does not work, the failover at DB-level
            // has not happened and therefore this site should be offline, as well.
            var dbOnline = await TryWriteDatabaseLogEntry();

            // Different response based on whether the site is in maintenance mode or not
            if (dashboardItem.OfflineForMaintenance)
            {
                throw new HttpException((int)HttpStatusCode.ServiceUnavailable, "Service is currently offline for maintenance!");
            }
            else
            {
                await UpdateDashboardEntry(dbOnline, dashboardItem);
                if(!dbOnline)
                    throw new HttpException((int)HttpStatusCode.ServiceUnavailable, "Service is currently offline since database is not active master or is offline!");

                // All is okay, so return a valid http response
                return Json(dashboardItem, JsonRequestBehavior.AllowGet);
            }
        }

        //
        // Allows taking the web site offline from Traffic Manager to simulate a failover
        //
        public async Task<ActionResult> ToggleOnline()
        {
            var dashboardItem = await GetDashboardItemForDeployment();
            await SetNewOnlineStatus(!dashboardItem.OfflineForMaintenance, dashboardItem);
            return Json(dashboardItem, JsonRequestBehavior.AllowGet);
        }

        //
        // Set of private helper methods that should make the controller methods more readable for you
        //
        #region Private Helper Method

        private async Task<ServiceDashboardEntity> GetDashboardItemForDeployment()
        {
            // 
            // First get all dashboard entries and then update the one for this region
            //
            var dashboardItems = await _dashboardDataAccess.GetDashboardRecordsAsync();
            var dashboardItem = dashboardItems.FirstOrDefault(d => (d.RegionName == _dashboardDataAccess.RegionName
                                                                    && d.DeploymentName == _dashboardDataAccess.DeploymentName)) ??
                                (ServiceDashboardEntity)new ServiceDashboardEntity()
                                                                {
                                                                    RegionName = _dashboardDataAccess.RegionName,
                                                                    DeploymentName = _dashboardDataAccess.DeploymentName,
                                                                    Online = true,
                                                                    OfflineForMaintenance = false,
                                                                    StatusMessage = ""
                                                                };

            //
            // First time the status is written to the table, create a new entity with default values
            //

            return dashboardItem;
        }

        private async Task UpdateDashboardEntry(bool dbOnline, ServiceDashboardEntity dashboardItem)
        {
            if (dbOnline)
            {
                dashboardItem.StatusMessage = string.Format("Traffic manager ping executed at {0} - {1}",
                    DateTime.UtcNow.ToLongDateString(),
                    DateTime.UtcNow.ToLongTimeString());
                dashboardItem.LastSuccessfulPing = DateTime.UtcNow;
                dashboardItem.Online = true;
            }
            else
            {
                dashboardItem.Online = false;
                dashboardItem.StatusMessage =
                    "Database is offline, therefore site is offline. Make sure to fail-over the databsae!";
            }
            await _dashboardDataAccess.UpdateDashboardRecordAsync(dashboardItem);
        }

        private async Task<bool> TryWriteDatabaseLogEntry()
        {
            try
            {
                await _logDataAccess.AddLogEntityAsync(
                    new LogEntity
                    {
                        LogDate = DateTime.UtcNow,
                        LogSiteRegion = _dashboardDataAccess.RegionName,
                        LogSiteSource = _dashboardDataAccess.DeploymentName,
                        LogMessage = "View Dashboard"
                    }
                    );
                return true;
            }
            catch
            {
                return false;
            }
        }

        private async Task SetNewOnlineStatus(bool newOfflineForMaintenanceStatus, ServiceDashboardEntity dashboardItem)
        {
            dashboardItem.OfflineForMaintenance = newOfflineForMaintenanceStatus;
            dashboardItem.Online = !newOfflineForMaintenanceStatus;
            dashboardItem.StatusMessage = string.Format
                (
                    "Switched from {0} to {1} at {2}-{3}!",
                    !dashboardItem.OfflineForMaintenance ? "Offline" : "Online",
                    dashboardItem.OfflineForMaintenance ? "Offline" : "Online",
                    DateTime.UtcNow.ToLongDateString(),
                    DateTime.UtcNow.ToLongTimeString()
                );
            await _dashboardDataAccess.UpdateDashboardRecordAsync(dashboardItem);
        }

        #endregion
    }
}