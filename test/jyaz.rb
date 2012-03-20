require '/home/james/Téléchargements/yaz4j-1.2/any/target/yaz4j-any-1.2-SNAPSHOT.jar'

conn = Java::OrgYaz4j::Connection.new("afi.chadwyck.co.uk:210/film",0)
conn.syntax = "SUTRS" 
p conn