using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(TrafficManagerWeb.Startup))]
namespace TrafficManagerWeb
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
