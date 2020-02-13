library(mailR)
library(knitr)
knit2html("reports.Rmd", options = "", force_v1 = T)

send.mail(from = "monitoring.gw@mtn.com", 
          to=c("mehibo.rufindji@mtn.com", "likadeu.sahi@mtn.com", "Cyrille.Babatounde2@mtn.com", 
               "patrice.dje@mtn.com", "Gaspard.Bayigane@mtn.com", "Reuben.Opata@mtn.com",
               "Freddie.Mokoena@mtn.com", "Jane.Mugenyi@mtn.com", "Bubacar.FalCamara@mtn.com", "Luisa.Rosa@mtn.com",
               "Wilfredo.Fernandes@mtn.com", "Etiandro.Ucha@mtn.com"
               ), 
          #to=c("mehibo.rufindji@mtn.com"),
          subject = paste0("Bundles reports H2H: ", format(Sys.time(), "%m/%d/%Y at %X", tz="Africa/Bissau")),
body = "reports.html", html=T,
smtp=list(host.name="smtp.office365.com", port=587, user.name="monitoring.gw@mtn.com", passwd="IMiE8XaK!DfZ", tls=T),
authenticate=T,
inline=T,
send = T
)
