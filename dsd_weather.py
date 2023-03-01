from datadog import initialize, statsd
import time
import random
import mysql.connector

options = {
    'statsd_host':'127.0.0.1',
    'statsd_port':8125
}

initialize(**options)

while True:

  temperature = round(random.uniform(70,90),2)
  humidity = round(random.uniform(30,40),2)
  pressure = round(random.uniform(800,1100),2)
 
  #Count
  statsd.increment('temperature.count.increment', temperature, tags=["environment:dev"])
  statsd.decrement('temperature.count.decrement', temperature, tags=["environment:dev"])  
  statsd.increment('humidity.count.increment', humidity, tags=["environment:dev"])
  statsd.decrement('humidity.count.decrement', humidity, tags=["environment:dev"])  
  statsd.increment('pressuse.count.increment', pressure, tags=["environment:dev"])
  statsd.decrement('pressure.count.decrement', pressure, tags=["environment:dev"]) 
 
  #Gauge
  statsd.gauge('temperature.gauge', temperature,tags=["environment:dev"])
  statsd.gauge('humidity.gauge',humidity, tags=["environment:dev"])
  statsd.gauge('pressure.gauge',pressure, tags=["environment:dev"])
 
  #Histogram (.avg, .median, .count, .max, .95percentile)
  statsd.histogram('temperature.histogram', temperature, tags=["environment:dev"])
  statsd.histogram('humidity.histogram', humidity, tags=["environment:dev"])
  statsd.histogram('pressure.histogram', pressure, tags=["environment:dev"])
  
  #Distribution (avg, count, max, min)
  statsd.distribution('temperature.distribution', temperature, tags=["environment:dev"])
  statsd.distribution('humidity.distribution', humidity, tags=["environment:dev"])
  statsd.distribution('pressure.distribution', pressure, tags=["environment:dev"])

  #Put Gauge data in mysql database
  cnx = mysql.connector.connect(user='weather_user', password='Datadog2023', database= 'weather_database')
  cursor = cnx.cursor()
  
  add_weather = ("INSERT INTO weather_data " "(temp,humidity,pressure) " "VALUES ( %(temp)s, %(humidity)s, %(pressure)s)")
  
  data_weather = {
    'temp' : temperature,
    'humidity' : humidity,
    'pressure' : pressure
  }
  
  cursor.execute(add_weather, data_weather)
  weather_id = cursor.lastrowid
  
  cnx.commit()
  cursor.close()
  cnx.close()


  time.sleep(10)
