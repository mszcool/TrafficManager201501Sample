using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;
using TrafficManagerWeb.Library.DataAccess.Interfaces;
using TrafficManagerWeb.Library.Entities;

namespace TrafficManagerWeb.Controllers
{
    public class HomeController : Controller
    {
        private ILogDataAccess _logDal;
        private IDashboardDataAccess _dashboardDal;

        public HomeController(IDashboardDataAccess dashboardDal, ILogDataAccess logDal)
        {
            _logDal = logDal;
            _dashboardDal = dashboardDal;
        }

        public async Task<ActionResult> Index()
        {
            try
            {
                await _logDal.AddLogEntityAsync(
                        new LogEntity
                        {
                            LogDate = DateTime.UtcNow,
                            LogSiteRegion =  _dashboardDal.RegionName,
                            LogSiteSource =  _dashboardDal.DeploymentName,
                            LogMessage = "Start Page Hit"
                        }
                    );

                return View();
            }
            catch (Exception ex)
            {
                ViewBag.ErrorMessage = ex.Message;
                ViewBag.ErrorDetails = ex.ToString();
                return View("Error");
            }
        }

        public async Task<ActionResult> Dashboard()
        {
            try
            {
                await _logDal.AddLogEntityAsync(
                        new LogEntity
                        {
                            LogDate = DateTime.UtcNow,
                            LogSiteRegion = _dashboardDal.RegionName,
                            LogSiteSource = _dashboardDal.DeploymentName,
                            LogMessage = "View Dashboard"
                        }
                    );

                var dashboardEntries = await _dashboardDal.GetDashboardRecordsAsync();
                return View(dashboardEntries);
            }
            catch (Exception ex)
            {
                ViewBag.ErrorMessage = ex.Message;
                ViewBag.ErrorDetails = ex.ToString();
                return View("Error");
            }
        }

        public async Task<ActionResult> Log()
        {
            try
            {
                await _logDal.AddLogEntityAsync(
                        new LogEntity
                        {
                            LogDate = DateTime.UtcNow,
                            LogSiteRegion = _dashboardDal.RegionName,
                            LogSiteSource = _dashboardDal.DeploymentName,
                            LogMessage = "View Database Log Entries"
                        }
                    );

                var logEntries = await _logDal.GetLogEntitiesAsync();
                return View(logEntries);
            }
            catch (Exception ex)
            {
                ViewBag.ErrorMessage = ex.Message;
                ViewBag.ErrorDetails = ex.ToString();
                return View("Error");
            }
        }
    }
}