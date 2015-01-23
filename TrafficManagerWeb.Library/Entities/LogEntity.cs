using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficManagerWeb.Library.Entities
{
    public class LogEntity
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int LogId { get; set; }
        public DateTime LogDate { get; set; }
        public string LogSiteSource { get; set; }
        public string LogSiteRegion { get; set; }
        public string LogMessage { get; set; }
    }
}
