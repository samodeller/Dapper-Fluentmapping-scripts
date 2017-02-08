SET NOCOUNT ON
GO
DECLARE @db varchar(50) = 'MyDB'
DECLARE @tempTable Table (TableName varchar(250))


INSERT INTO @tempTable

Select  distinct ltrim(rtrim(t.table_name)) as table_name
FROM     information_schema.columns c
         INNER JOIN information_schema.tables t
           ON c.table_name = t.table_name
              AND c.table_schema = t.table_schema
              AND t.table_type = 'BASE TABLE'
WHERE t.TABLE_CATALOG = @db
And t.table_name in ('Company','Contact','Contact_Customer','Customer','Customer_Area','Customer_Extension','Customer_User','Messaging_Action','Mobile_Message','Mobile_Message_Response','Mobile_Message_Type','Product','Product_Category','Product_Sub_Category','Product_Type','Sales_Order','Sales_Order_Item','Task','Task_Staging','Task_Status','Task_Step','Task_Step_Condition','Task_Step_Exception','Task_Step_Exception_Comment','Task_Step_Metadata','Task_Step_Metadata_Value','Task_Step_Route','Task_Step_Type','Task_Step_Type_Mandatory','Task_Step_Type_Value','Task_Template','Task_Template_Step','Task_Template_Step_Condition','Task_Template_Step_Exception','Task_Template_Step_Exception_Contact','Task_Template_Step_Route','User_Access','User_Blackbox_Location','User_Breadcrumb_Location','User_Location','User_Messaging_Action','User_Messaging_Action_Archive','User_Messaging_Action_Response','User_Modification','User_Route_Event','User_Route_Locations','User_Settings','User_Type','Users')
ORDER BY table_name

Select TableName + ',' from @tempTable

DECLARE @currentTable varchar(250)

Select top 1 @currentTable = TableName from @tempTable 


While (@@ROWCOUNT > 0) Begin
	Delete from @tempTable where TableName = @currentTable
	DECLARE @table_name varchar(250) = @currentTable
	-- Entities
	
	Select '[Serializable]'  + CHAR(13)+CHAR(10) + 
		'[DataContract]'  + CHAR(13)+CHAR(10) + 
		'[Table("' + replace(dbo.InitCap(Replace(@table_name,'_',' ')),' ','') + '")]'  + CHAR(13)+CHAR(10) + 
		'public class ' + replace(dbo.InitCap(Replace(@table_name,'_',' ')),' ','') + CHAR(13)+CHAR(10) + 
		'{'  + CHAR(13)+CHAR(10) + 
		'public ' + replace(dbo.InitCap(Replace(@table_name,'_',' ')),' ','') + '()'  + CHAR(13)+CHAR(10) + 
		'{'  + CHAR(13)+CHAR(10) + 
		'}'
	SELECT   CHAR(13)+CHAR(10) + '[DataMember]'  + CHAR(13)+CHAR(10) + 
			 'public ' +
			 case when data_type = 'uniqueidentifier' then 'Guid ' 
				else 
				case when data_type = 'varchar' or data_type = 'nvarchar' then 'string ' 
					else 
					case when data_type = 'bit' then 'bool'  +  (case when IS_NULLABLE = 'YES' then '? ' else ' ' end)
						else 
						case when data_type = 'datetime' then 'DateTime' +  (case when IS_NULLABLE = 'YES' then '? ' else ' ' end) 
							else 
							case when data_type = 'float' then 'double'  +  (case when IS_NULLABLE = 'YES' then '? ' else ' ' end)
								else 
								case when data_type = 'bigint' then 'long'  +  (case when IS_NULLABLE = 'YES' then '? ' else ' ' end)
									else
									case when data_type = 'int' then 'int'  +  (case when IS_NULLABLE = 'YES' then '? ' else ' ' end)
										else
										case when data_type = 'image' or data_type = 'varbinary' then 'sbyte[] '
											else
											case when data_type = 'decimal' or data_type = 'money' then  'decimal'  +  (case when IS_NULLABLE = 'YES' then '? ' else ' ' end)
											end
										end
									end
								end
							end
						 end
					 end
				 end
			 end 
			 + replace(dbo.InitCap(Replace(c.column_name,'_',' ')),' ','')  + ' { get; set; }'
	FROM     information_schema.columns c
			 INNER JOIN information_schema.tables t
			   ON c.table_name = t.table_name
				  AND c.table_schema = t.table_schema
				  AND t.table_type = 'BASE TABLE'
	WHERE c.Table_name = @table_name
	--AND   CHARINDEX('_',c.column_name) > 0
	ORDER BY column_name
		 
	Select '}' 

	-- Mapping Queries
	Select 'public class ' + replace(dbo.InitCap(Replace(@table_name,'_',' ')),' ','') + 'Map : EntityMap<' + replace(dbo.InitCap(Replace(@table_name,'_',' ')),' ','') + '>' + CHAR(13)+CHAR(10) + 
		'{' + CHAR(13)+CHAR(10) + 
		'public ' + replace(dbo.InitCap(Replace(@table_name,'_',' ')),' ','') + 'Map()' + CHAR(13)+CHAR(10) + 
		'{' + CHAR(13)+CHAR(10) 
		SELECT   'Map(t => t.'+ replace(dbo.InitCap(Replace(c.column_name,'_',' ')),' ','') + ').ToColumn("' + c.column_name +'");'
		FROM     information_schema.columns c
					INNER JOIN information_schema.tables t
					ON c.table_name = t.table_name
						AND c.table_schema = t.table_schema
						AND t.table_type = 'BASE TABLE'
		WHERE c.Table_name = @table_name
		AND   CHARINDEX('_',c.column_name) > 0
		ORDER BY c.column_name
		 
		Select '}' + CHAR(13)+CHAR(10) + '}'

	-- Named Queries
	Select '/*' + @table_name + '*/'+ CHAR(13)+CHAR(10) + 
	'public const string  ' + UPPER(@table_name) + '_FIND_ALL = "SELECT ' 
		+ LOWER(SUBSTRING(@table_name, 1, 1)) + '.* FROM dbo.' + @table_name + ' ' + LOWER(SUBSTRING(@table_name, 1, 1)) +';";'

	Select 'public const string  ' + UPPER(@table_name) + '_FIND_BY_' + UPPER(c.column_name) + ' = "SELECT ' 
		+ LOWER(SUBSTRING(@table_name, 1, 1)) + '.* FROM dbo.' + @table_name + ' ' + LOWER(SUBSTRING(@table_name, 1, 1)) + ' WHERE ' + LOWER(SUBSTRING(@table_name, 1, 1)) 
		+ '.' + c.column_name + ' = ' + char(39) + '{0}' +char(39) +';";'
		FROM     information_schema.columns c
					INNER JOIN information_schema.tables t
					ON c.table_name = t.table_name
						AND c.table_schema = t.table_schema
						AND t.table_type = 'BASE TABLE'
		WHERE c.Table_name = @table_name
--		AND   CHARINDEX('_',c.column_name) > 0
		ORDER BY c.column_name
	Select top 1 @currentTable = TableName from @tempTable 
End
