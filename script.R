#paquetes
library(airqualityES) #paquete para trabajar la calidad del aire en España
library(tidyverse)#paquete para poder manipular y visualizar los datos
library(pxR) #paquete para trabajar con archivos .px
library(dplyr) #paquete para operar con dataframes
#carga de datos

zonas_verdes <- read.px("INPUT/DATA/zonas_verdes.px")$DATA#carga un archivo con datos sobre las zonas verdes

alzheimer <- read.px("INPUT/DATA/alzheimer_total.px")$DATA#carga un achivo con datos sobre el alzheimer

data("airqES")#carga el conjunto de datos con información sobre la calidad del aire en España

#Modificacion Tablas

#filtrar y modificar los datos de 2018
calidad_aire <- airqES %>%
  filter(year == 2018) %>%#filtra el airqES para el año 2018
  mutate(media_mensual = apply(.[, c(8:38)], 1, mean, na.rm = TRUE))%>%#creamos una columna llamada media_mensual, se calcula la media de las columnas 8-38 por cada fila (evitando los valores NA) 
  select(month, province, station_id, pollutant, media_mensual)#se filtran las columnas month, province, station_id, pullutant y media_mensual


#quitamos los valores de zonas_verdes que no se centran en provincias
zonas_verdes_df <- zonas_verdes$value
zonas_verdes_df<-zonas_verdes_df[-c(1,2,3,4,5), ]#eliminamos las filas 1, 2, 3, 4 y 5

#preparamos los datos de alzheimer
alzheimer_df<-alzheimer$value
alzheimer_df<-alzheimer_df[,-c(1,2)]#eliminamos las columnas 1 y 2 


#pivotar zonas verdes
wide_zonas_verdes<-
  zonas_verdes_df%>%
  pivot_wider(names_from = "Nivel.de.satisfacción", values_from = "value")

#creamos un vector con los nombres de los meses
meses<-c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", 
         "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")
#remplazamos los meses en la tabla
calidad_aire$month<-meses[calidad_aire$month]


#creamos un vector con los nombres de las provincias
factor(provincias)



calidad_aire$province<-provincias[calidad_aire$province]

print(calidad_aire)

#pivotamos calidad del aire
wide_calidad_aire<-
  calidad_aire%>%
  pivot_wider(names_from = "month", values_from = "media_mensual")


#agrupar meses
wide_calidad_aire<-
  wide_calidad_aire%>%
  mutate(media_anual = apply(.[, c(4:15)], 1, mean, na.rm = TRUE))


#quitamos los datos por meses
wide_calidad_aire<-wide_calidad_aire[,-c(4:15)]


#eliminamos algunas columnas de valoracion
wide_zonas_verdes<-wide_zonas_verdes[,-c(2:5)]

alzheimer_zonas_verdes<-left_join(x = alzheimer_df, y = wide_zonas_verdes, by = c("10 Comunitates.y.Ciudades.Autónomas")) 

alzheimer_zonas_verdes<-alzheimer_zonas_verdes[-c(1),]

#calculamos los porcentajes de los contaminantes
wide_calidad_aire <- wide_calidad_aire %>%
  mutate(
    porcentaje = case_when(
      !is.na(media_anual) & pollutant == "PM10" ~ (media_anual / 40) * 100,
      !is.na(media_anual) & pollutant == "PM2.5" ~ (media_anual / 25) * 100,
      !is.na(media_anual) & pollutant == "Pb" ~ (media_anual / 0.5) * 100,
      !is.na(media_anual) & pollutant == "As" ~ (media_anual / 6) * 100,
      !is.na(media_anual) & pollutant == "Cd" ~ (media_anual / 5) * 100,
      !is.na(media_anual) & pollutant == "Ni" ~ (media_anual / 20) * 100,
      !is.na(media_anual) & pollutant == "B(a)P" ~ (media_anual / 1) * 100,
      TRUE ~ NA_real_
    )
  )

#agrupamos por provincia y contaminante y calculamos el promedio por provincia
wide_calidad_aire <- group_by(.data = wide_calidad_aire, province, pollutant) %>% 
  dplyr::summarise(media_porcentaje = mean(porcentaje, na.rm = TRUE)) %>% 
  ungroup() %>% 
  group_by(province) %>% 
  dplyr::summarise(airQ = mean(media_porcentaje, na.rm = TRUE)) %>% 
  ungroup()


provincias <- c("Alava", "Albacete", "Alicante", "Almeria", "Asturias", "Avila", "Badajoz", 
                "Baleares", "Barcelona", "Bizkaia", "Burgos", "Caceres", "Cadiz", "Cantabria", 
                "Castellon", "Ciudad Real", "Cordoba", "Coruña", "Cuenca", "Gipuzkoa", 
                "Girona", "Granada", "Guadalajara", "Huelva", "Huesca", "Jaen", "Leon", 
                "Lleida", "Lugo", "Madrid", "Málaga", "Murcia", "Navarra", "Ourense", 
                "Palencia", "Palmas", "Pontevedra", "Rioja", "Salamanca", "Santa_Cruz_de_Tenerife", 
                "Segovia", "Sevilla", "Soria", "Tarragona", "Teruel", "Toledo", "Valencia", 
                "Valladolid", "Zamora", "Zaragoza")
Comunidades <- c("16 País Vasco ", "08 Castilla-La Mancha", "10 Comunitat Valenciana", "01 Andalucía", "03 Asturias, Principado de",
                 "07 Castilla y León", "11 Extremadura", "04, Baleares, Illes", "09 Cataluña", "16 País Vasco ", 
                 "07 Castilla y León", "11 Extremadura", "01 Andalucía", "06 Cantabria", "10 Comunitat Valenciana", 
                 "08 Castilla-La Mancha", "01 Andalucía", "12 Galicia", "08 Castilla-La Mancha", "16 País Vasco ", 
                 "09 Cataluña", "01 Andalucía", "08 Castilla-La Mancha", "01 Andalucía", "02 Aragón", "01 Andalucía", 
                 "07 Castilla y León", "09 Cataluña", "12 Galicia", "13 Madrid, Comunidad de", "01 Andalucía", "14 Murcia, Región de", 
                 "15 Navarra, Comunidad Foral de", "12 Galicia", "07 Castilla y León", "Islas 05 Canarias", "12 Galicia", "17 Rioja, La", 
                 "07 Castilla y León", "Islas 05 Canarias", "07 Castilla y León", "01 Andalucía", "07 Castilla y León", 
                 "09 Cataluña", "02 Aragón", "08 Castilla-La Mancha", "10 Comunitat Valenciana", 
                 "07 Castilla y León", "07 Castilla y León", "02 Aragón")
# Crear el dataframe de provincias y 10 Comunitates
provincias_10 Comunitates <- data.frame(
  province = provincias,
  10 Comunitat_autonoma = 10 Comunitates
)
#combinamos calidad del aire con las 10 Comunitates autónomas
calidad_aire_10 Comunitates<-left_join(wide_calidad_aire,provincias_10 Comunitates)

#calculamos la calidad del aire por 10 Comunitat autónoma
airQ<- calidad_aire_10 Comunitates%>%
  group_by(10 Comunitat_autonoma)%>%
  dplyr::summarise(media_airQ=mean(airQ))
view(airQ)
