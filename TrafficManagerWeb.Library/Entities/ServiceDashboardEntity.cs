using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TrafficManagerWeb.Library.Entities
{
    public class ServiceDashboardEntity : TableEntity
    {
        public const string PartitionKeyString = "ServiceDashboardPartition";

        public static string GetRowKey(string regionName, string deploymentName)
        {
            return string.Format("{0}_{1}", regionName, deploymentName);
        }

        public ServiceDashboardEntity() 
        {
            this.PartitionKey = ServiceDashboardEntity.PartitionKeyString;
        }

        private string _regionName;
        public string RegionName 
        {
            get { return _regionName; }
            set
            {
                _regionName = value;
                RowKey = GetRowKey(_regionName, DeploymentName);
            }
        }

        private string _deploymentName;
        public string DeploymentName 
        {
            get { return _deploymentName; }
            set 
            { 
                _deploymentName = value;
                RowKey = GetRowKey(RegionName, _deploymentName);
            }
        }

        public bool Online { get; set; }
        public string StatusMessage { get; set; }
        public DateTime LastSuccessfulPing { get; set; }
        public bool OfflineForMaintenance { get; set; }
    }
}
