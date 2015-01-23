using Microsoft.WindowsAzure;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.RetryPolicies;
using Microsoft.WindowsAzure.Storage.Table;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TrafficManagerWeb.Library.DataAccess.Interfaces;
using TrafficManagerWeb.Library.Entities;

namespace TrafficManagerWeb.Library.DataAccess
{
    public class AzureTableServiceDashboardDal : IDashboardDataAccess
    {
        public string RegionName
        {
            get { return ConfigurationManager.AppSettings["TrafficManagerSample.RegionName"]; }
        }

        public string DeploymentName
        {
            get { return ConfigurationManager.AppSettings["TrafficManagerSample.DeploymentName"]; }
        }

        public async Task<List<Entities.ServiceDashboardEntity>> GetDashboardRecordsAsync()
        {
            var tableRef = CreateTableStorage();

            var tableQuery = new TableQuery<ServiceDashboardEntity>().Where
                                    (
                                            TableQuery.GenerateFilterCondition("PartitionKey", QueryComparisons.Equal, ServiceDashboardEntity.PartitionKeyString)
                                    );
            var queryResults = await tableRef.ExecuteQuerySegmentedAsync<ServiceDashboardEntity>(tableQuery, null);

            return (from d in queryResults
                    select d).ToList();
        }

        public async Task UpdateDashboardRecordAsync(Entities.ServiceDashboardEntity recordToUpdate)
        {
            var tableRef = CreateTableStorage();

            var updateRecord = new ServiceDashboardEntity
            {
                RegionName = recordToUpdate.RegionName,
                DeploymentName = recordToUpdate.DeploymentName,
                Online = recordToUpdate.Online,
                OfflineForMaintenance = recordToUpdate.OfflineForMaintenance,
                LastSuccessfulPing = recordToUpdate.LastSuccessfulPing,
                StatusMessage = recordToUpdate.StatusMessage
            };

            var updateOp = TableOperation.InsertOrMerge(updateRecord);
            await tableRef.ExecuteAsync(updateOp);
        }

        #region Private Helper Methods

        private CloudTable CreateTableStorage()
        {
            var storage = CloudStorageAccount.Parse
                            (
                                ConfigurationManager.ConnectionStrings["TrafficManagerSample.DashboardStorageConnection"].ConnectionString
                            );
            var tableClient = storage.CreateCloudTableClient();
            tableClient.DefaultRequestOptions = new TableRequestOptions()
            {
                RetryPolicy = new LinearRetry(TimeSpan.FromSeconds(1), 5)
            };
            var table = tableClient.GetTableReference("dashboardTable");
            table.CreateIfNotExists();

            return table;
        }

        #endregion
    }
}
