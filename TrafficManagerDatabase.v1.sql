﻿CREATE TABLE [dbo].[LogEntries] (
    [LogId] [int] NOT NULL IDENTITY,
    [LogDate] [datetime] NOT NULL,
    [LogSiteSource] [nvarchar](max) NOT NULL,
    [LogSiteRegion] [nvarchar](max) NOT NULL,
    [LogMessage] [nvarchar](max) NOT NULL,
    CONSTRAINT [PK_dbo.LogEntries] PRIMARY KEY ([LogId])
)
CREATE INDEX [IX_LogDate] ON [dbo].[LogEntries]([LogDate])
CREATE TABLE [dbo].[__MigrationHistory] (
    [MigrationId] [nvarchar](150) NOT NULL,
    [ContextKey] [nvarchar](300) NOT NULL,
    [Model] [varbinary](max) NOT NULL,
    [ProductVersion] [nvarchar](32) NOT NULL,
    CONSTRAINT [PK_dbo.__MigrationHistory] PRIMARY KEY ([MigrationId], [ContextKey])
)
INSERT [dbo].[__MigrationHistory]([MigrationId], [ContextKey], [Model], [ProductVersion])
VALUES (N'201501231405403_InitialSetup', N'TrafficManagerWeb.Library.Migrations.Configuration',  0x1F8B0800000000000400CD55CB6EDB3010BC17E83F08BCC7B4934B6BC809523B2902C47111B9B9D3D24A21CA57C595617D5B0FFDA4FE4257B2643976E238410F3D925CCECECE0E977F7EFD0E2F565A054BC8BDB466C406BD3E0BC0C43691261BB102D3934FECE2FCE387F02AD1ABE0A18D3BABE2E8A6F123F688E8869CFBF811B4F03D2DE3DC7A9B622FB69A8BC4F2D37EFF331F0C38100423AC2008EF0B835243BDA0E5D89A181C16424D6D02CA37FB7412D5A8C19DD0E09D8861C4AEB4C39205974A0A4A1E814A59208CB12890A80DBF7B8830B7268B1C6D08352F1D505C2A948786F2B00B3F967DFFB462CFBB8B2D545C78B4FA8D8083B3460EBE7BFD5DA2B28D5C24D815098B25098A421AC86BE548A69FEAD666138162B2A8CE60852CD84D5E69375679A318E60509C6BB56F0752FDA9EF1179A164E8573E49EAD26363B41B4EEE0F8247A7B9D7A8DC1637FA8DC4D26B4B9C860E7945213D36B997BACA45888CA12E344EF853D2BD7B6144D9E8D163B35874DFED7DDBC47681DC2826FB95DCAA426537A04DDAB027A446CAC2418EC02A6C2C8143CCEED0F20FB91BB4E775EC7FFE354EE7DA28EB0EB336D3A60C47DB143BE3D60C209789911FAD6B83110575574A06DCC8D492D49EB20C73202DCE6DA86B4C70DD929A04888E7658E321531D2710CDE931D58F0205451CFAC0524376656A02BF0D27BD00B553EADE970FEFAB53DE51CCE5CB5F2FFA204A229A90498992F8554C986F7F57A6AF22320AA967D05DAAFDD412398E0B272837467CD91408D7C1370601272FA1CB45304E66726124B780F379A6BB79089B86CDFCCCB20AF37E2A9ECE1448A2C17DA3718DDFDEAD3E4D5AF79FE173D435F5067070000 , N'6.1.2-31219')

