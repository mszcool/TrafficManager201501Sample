namespace TrafficManagerWeb.Library.Migrations
{
    using System;
    using System.Data.Entity.Migrations;
    
    public partial class InitialSetup : DbMigration
    {
        public override void Up()
        {
            base.CreateTable("dbo.LogEntities", c => new
                    {
                        LogId = c.Int(nullable: false, identity: true),
                        LogDate = c.DateTime(nullable: false),
                        LogSiteSource = c.String(nullable: false),
                        LogSiteRegion = c.String(nullable: false),
                        LogMessage = c.String(nullable:false)
                    })
                    .PrimaryKey(t => t.LogId)
                    .Index(t => t.LogDate);
        }
        
        public override void Down()
        {
            base.DropIndex("dbo.LogEntities", new[] { "LogDate" });
            base.DropTable("dbo.LogEntities");
        }
    }
}
