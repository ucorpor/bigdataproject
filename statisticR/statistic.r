setwd("~/r-project/")
install.packages("RJDBC")
library(RJDBC)
driver <- JDBC("oracle.jdbc.OracleDriver", classPath="C:/Users/parameeva/bigdataproject/statisticR/ojdbc6.jar", " ")
connection <- dbConnect(driver, "jdbc:oracle:thin:@10.154.98.254:1521:cdb", "system","welcome1")

#select top likes
topLikes<- dbGetQuery(connection, "select s.title, s.nameartist, s.year, c.cn from (select idsong, count(*) cn from likes_hive group by idsong) c, songsdesc_hive s where c.idsong=s.idsong order by c.cn desc")

#select top likes by artist name
topArtistNameByLikes <- dbGetQuery(connection, "select s.nameartist, s.title, s.year, c.cn from (select idsong, count(*) cn from likes_hive group by idsong) c, songsdesc_hive s where c.idsong=s.idsong and s.nameartist like '%Toussaint Morrison%' order by c.cn desc")

#select top artist by likes
topArtistByLikes<- dbGetQuery(connection, "select distinct s.nameartist, c.cn from (select idsong, count(*) cn from likes_hive group by idsong) c, songsdesc_hive s where c.idsong=s.idsong order by c.cn desc")

#select top likes by genre
topLikesByGenres <- dbGetQuery(connection, "select sd.nameartist, sd.title, sd.year, c.cn from genres_hive g, songs_hive s, songsdesc_hive sd, (select idsong, count(*) cn from likes_hive group by idsong) c where g.idgenre=s.idgenre and s.idsong=sd.idsong and g.title like '%RnB%' and sd.idsong=c.idsong order by c.cn desc")

#select top active users
topActiveUsers <- dbGetQuery(connection, "select p.email, p.name, p.surname, sd.likes, sd.recommends from profiles_hive p, (select email, count(*)+sum(recommend) cn, count(*) likes, sum(recommend) recommends from likes_hive group by email) sd where p.email=sd.email order by sd.cn desc")

#select top recommends
topRecommends<- dbGetQuery(connection, "select s.title, s.nameartist, s.year, c.cn from (select idsong, sum(recommend) cn from likes_hive group by idsong) c, songsdesc_hive s where c.idsong=s.idsong order by c.cn desc")

#select top recommends by artist name
topRecommendsByArtist<- dbGetQuery(connection, "select s.nameartist, s.title, s.year, c.cn from (select idsong, sum(recommend) cn from likes_hive group by idsong) c, songsdesc_hive s where c.idsong=s.idsong and s.nameartist like '%The Polish%' order by c.cn desc")

#select top artist by recommends
topArtistByRecommends<- dbGetQuery(connection, "select distinct s.nameartist, sum(c.cn) cn from (select idsong, sum(recommend) cn from likes_hive group by idsong) c, songsdesc_hive s where c.idsong=s.idsong group by s.nameartist order by cn desc")

#select top recommens by genre
#topRecommendsByGenres<- dbGetQuery(connection, "select sd.nameartist, sd.title, sd.year, c.cn from genres_hive g, songs_hive s, songsdesc_hive sd, (select idsong, sum(recommend) cn from likes_hive group by idsong) c where g.idgenre=s.idgenre and s.idsong=sd.idsong and g.title like '%RnB%' and sd.idsong=c.idsong order by c.cn desc")

#select top album
topAlbum <- dbGetQuery(connection, "select a.title, c.cn from albums_hive a, (select s.idalbum, count(*) cn from likes_hive ls, songs_hive s where ls.idsong=s.idsong group by s.idalbum) c where a.idalbum=c.idalbum order by c.cn desc")

attach(topAlbum)
ggplot(topAlbum, aes(TITLE, CN)) + geom_bar(stat = "identity", position = "dodge", fill= "grey50", colour = "black")
#dbDisconnect(connection)
allUsers<- dbGetQuery(connection, "select * from profiles_hive")
allSong <- dbGetQuery(connection, "select sd.*, g.title from song_hive s, genres_hive g, songsdesc_hive sd where g.idgenre=s.idgenre and s.idsong=sd.idsong")
install.packages("rpart")
library(rpart)

allSongsRecom <- dbGetQuery(connection, "select decode(gender, 1, 'M', 2, 'F') gender, to_number(substr(birthday, -4, 4)) year, decode(recommend, 0, 'N', 1, 'Y') recommend, g.title from profiles_hive p, likes_hive l, songs_hive s, genres_hive g where p.email=l.email and l.idsong=s.idsong and s.idgenre=g.idgenre")
tree.rp1 <- rpart(RECOMMEND~., allSongsRecom)
tree.rp1
plot(tree.rp1)
text(tree.rp1, pretty=0)
allSongsRecom_ER_pro <- dbGetQuery(connection, "select p.email, decode(gender, 1, 'M', 2, 'F') gender, to_number(substr(birthday, -4, 4)) year, g.title from profiles_hive p, (select g.title from genres_hive g where g.idgenre in (1, 7, 8)) g where p.email not in (select distinct email from likes_hive)")
prediction <- predict(tree.rp1, allSongsRecom_ER_pro)
table(prediction)
prediction
View(prediction)
answer <- data.frame(allSongsRecom_ER_pro, prediction)
View(answer)

install.packages("rattle")
library(rattle)
attach(answer)
fit <-rpart(answer$GENDER ~ answer$Y, method = "class", answer)
plotcp(fit)
printcp(fit)
plot(fit, uniform=TRUE, main="tree")
