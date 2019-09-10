
declare @table nvarchar(128)
declare @sql nvarchar(max)
set @sql = ''
DECLARE tableCursor CURSOR FOR  
SELECT name from sys.tables

open tableCursor
fetch next from tableCursor into @table

CREATE TABLE #TempTable( Tablename nvarchar(max), Bytes int, RowCnt int)

WHILE @@FETCH_STATUS = 0  
begin
    set @sql = 'insert into #TempTable (Tablename, Bytes, RowCnt) '
    set @sql = @sql + 'select '''+@table+''' "Table", sum(t.rowsize) "Bytes", count(*) "RowCnt" from (select (0'

    select @sql = @sql + ' + isnull(datalength([' + name + ']), 1) ' 
        from sys.columns where object_id = object_id(@table)
    set @sql = @sql + ') as rowsize from ' + @table + ' ) t '
    exec (@sql)
    FETCH NEXT FROM tableCursor INTO @table  
end

PRINT @sql

CLOSE tableCursor   
DEALLOCATE tableCursor

select * from #TempTable
select sum(bytes) "Sum" from #TempTable

DROP TABLE #TempTable