/*    ==Scripting Parameters==

    Source Server Version : SQL Server 2016 (13.0.4001)
    Source Database Engine Edition : Microsoft SQL Server Standard Edition
    Source Database Engine Type : Standalone SQL Server

    Target Server Version : SQL Server 2016
    Target Database Engine Edition : Microsoft SQL Server Standard Edition
    Target Database Engine Type : Standalone SQL Server
*/

USE [iMIS_Prod]
GO

/****** Object:  StoredProcedure [dbo].[usp_Compile_Site_Links]    Script Date: 2/6/2018 4:30:42 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


--/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT TOP (1000) [location]
--      ,[name]
--      ,[docType]
--      ,[depth]
--      ,[DocumentVersionKey]
--  FROM [iMIS_Prod].[dbo].[WSMA_Site_Links]

CREATE proc [dbo].[usp_Compile_Site_Links] as
--search for document (iqa, web page, or whatever), put document name here
declare @name varchar(250)='%';
 
declare @filterDocType varchar(3)='con'; --con is website content, iqd is iqa, bus is business object, fol is folder
--uncomment the where clause at the end if you want to filter by doc type
 
declare @i int, @depth int, @parentKey uniqueidentifier, @docType varchar(3), @DocumentVersionKey uniqueidentifier, @altname varchar(100);
declare @location varchar(500); declare @targets cursor;

--drop table WSMA_Site_Links
--create table WSMA_Site_Links (location varchar(500), name varchar(100), alternatename varchar(100), docType varchar(3), depth int, DocumentVersionKey uniqueidentifier);

truncate table WSMA_Site_Links
 
set @targets = cursor for
select d.documentName, d.AlternateName, h.Depth, h.ParentHierarchyKey, d.documenttypecode, d.DocumentVersionKey
from DocumentMain d join Hierarchy h on d.DocumentVersionKey = h.UniformKey
where d.DocumentName like '%'+@name+'%'
and d.DocumentStatusCode = 40
and H.RootHierarchyKey = '1CF36D67-5EEB-4914-B2CE-7A7611513DB4'
 
open @targets;
fetch next from @targets into @name, @altname, @depth, @parentKey, @docType, @DocumentVersionKey;
 
while @@fetch_status = 0 begin
  set @location = @name;
  set @i = 1;
 
  while (@i < @depth) begin
    select @parentKey = h.ParentHierarchyKey, @location = d.DocumentName+'/'+@location
    from DocumentMain d join Hierarchy h on d.DocumentVersionKey = h.UniformKey
    where h.HierarchyKey = @parentKey and d.DocumentStatusCode = 40;
    
    set @i = @i+1;
  end
 
  insert into WSMA_Site_Links values (@location, @name, @altname, @docType, @depth, @DocumentVersionKey);
  fetch next from @targets into @name, @altname, @depth, @parentKey, @docType, @DocumentVersionKey;
end
 
--select '/'+Location as Location, name, docType, depth, DocumentVersionKey 
--from WSMA_Site_Links where docType = @filterDocType
--order by name, location

GO