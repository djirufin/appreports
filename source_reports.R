library(dplyr)
library(RMySQL)
library(RJDBC)
library(ggplot2)

#sQL for MySQL
query_mysql <- "SELECT CASE A.MODULE WHEN 'BUNDLES3G' then 'BUNDLES3G_EVD_123' ELSE A.MODULE END MODULE, B.TOTAL YESTERDAY, A.TOTAL TODAY, (A.TOTAL - B.TOTAL) DIFFERENCE, ROUND(A.TOTAL*100/(B.TOTAL), 1) PCT 
FROM (SELECT MODULE, COUNT(DISTINCT MSISDN) DIST ,COUNT(BUNDLE_PRICE) NBRE, SUM(BUNDLE_PRICE) TOTAL FROM COMMON.CDR
WHERE TRANSDATE = CURDATE() AND STATUS_REASON = 'BUNDLE_SUCCESS' AND LAST_UPDATE <= current_timestamp() GROUP BY MODULE) A 
LEFT JOIN (SELECT MODULE, COUNT(DISTINCT MSISDN)DIST,COUNT(BUNDLE_PRICE) NBRE, SUM(BUNDLE_PRICE) TOTAL FROM COMMON.CDR
WHERE TRANSDATE = date_sub(CURDATE(), INTERVAL 1 DAY) AND STATUS_REASON = 'BUNDLE_SUCCESS' AND LAST_UPDATE <= date_sub(current_timestamp(), interval 1 day)
GROUP BY MODULE) B USING (MODULE) ORDER BY PCT DESC"

#SQL for oracle
query_orcl <- "SELECT MODULE, B.TOTAL YESTERDAY, A.TOTAL TODAY, (A.TOTAL - B.TOTAL) DIFFERENCE, ROUND(A.TOTAL*100/(B.TOTAL), 1) PCT 
FROM (SELECT MODULE, COUNT(DISTINCT MSISDN) DIST ,COUNT(BUNDLE_PRICE) NBRE, SUM(BUNDLE_PRICE) TOTAL FROM CDR
WHERE TRANSDATE = trunc(sysdate) AND STATUS_REASON = 'BUNDLE_SUCCESS' AND LAST_UPDATE <= sysdate GROUP BY MODULE) A 
LEFT JOIN (SELECT MODULE, COUNT(DISTINCT MSISDN)DIST,COUNT(BUNDLE_PRICE) NBRE, SUM(BUNDLE_PRICE) TOTAL FROM CDR
WHERE TRANSDATE = trunc(sysdate-1) AND STATUS_REASON = 'BUNDLE_SUCCESS' AND LAST_UPDATE <= sysdate-1
GROUP BY MODULE) B USING (MODULE) ORDER BY PCT DESC"

#Connection to server 39
myDB39 <- dbConnect(MySQL(), user='everaldo', password='123456', dbname='COMMON', host='192.168.100.39')
rs39 <- dbSendQuery(myDB39, query_mysql)
data39 <- fetch(rs39, n=-1)


#Connection to server 15
myDB15 <- dbConnect(MySQL(), user='mtn', password='Mtn@123456', dbname='COMMON', host='192.168.100.15')
rs15 <- dbSendQuery(myDB15, query_mysql)
data15 <- fetch(rs15, n=-1)

#Connection to oracle server
drv <- JDBC("oracle.jdbc.OracleDriver", classPath = "lib/ojdbc6.jar")
orcl <- dbConnect(drv, "jdbc:oracle:thin:@//10.100.2.179:1521/vasdb", "vas", "vas")
dataOrcl <- dbGetQuery(orcl, query_orcl)

#bind dataframes
#Get Hourly trend
query_hist_orcl <- "select module, transdate, to_char(last_update, 'HH24') hourly, sum(bundle_price) total from cdr where transdate >= trunc(sysdate-1)
and status_reason = 'BUNDLE_SUCCESS'
group by module, transdate, to_char(last_update, 'HH24')
order by 1, 2, 3"

data_hist_orcl <- dbGetQuery(orcl, query_hist_orcl)
data_hist_orcl$TRANSDATE <- as.character(as.Date(data_hist_orcl$TRANSDATE))
df_bombastico <- data_hist_orcl %>% filter(MODULE=='BOMBASTICO')
ggplot(df_bombastico, aes(x=HOURLY, y=TOTAL, group=TRANSDATE))+geom_line(aes(color=TRANSDATE)) + geom_point(aes(color=TRANSDATE))


#Clear resultset and close connections
dbClearResult(dbListResults(myDB15)[[1]])
dbClearResult(dbListResults(myDB39)[[1]])
dbDisconnect(myDB15)
dbDisconnect(myDB39)
dbDisconnect(orcl)