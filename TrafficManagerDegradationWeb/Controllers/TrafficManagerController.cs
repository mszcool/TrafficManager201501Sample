using System;
using System.Net;
using System.Threading.Tasks;
using System.Web;
using System.Web.Mvc;

namespace TrafficManagerDegradationWeb.Controllers
{
    public class TrafficManagerController : Controller
    {
        /// <summary>
        /// Default route redirects to index.html
        /// </summary>
        public ActionResult Home()
        {
            return Redirect("/index.html");
        }

        /// <summary>
        /// Ping exists to have the same ping-endpoint for traffic manager verifications as the main website
        /// </summary>
        public ActionResult Ping()
        {
            // Always return an http 200 OK for the ping at the error page
            return Content("ok");
        }
    }
}